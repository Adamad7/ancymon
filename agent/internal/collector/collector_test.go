package collector_test

import (
	"testing"
	"time"

	"ancymon/agent/internal/collector"

	"github.com/shirou/gopsutil/v3/disk"
	"github.com/shirou/gopsutil/v3/mem"
)

type mockHardwareInspector struct {
	cpuPercent  float64
	cpuTemp     *float64
	totalRAM    uint64
	usedRAM     uint64
	usedRAMPct  float64
	rxBytes     uint64
	txBytes     uint64
	partitions  []disk.PartitionStat
	diskUsages  map[string]*disk.UsageStat
	hostnameStr string
}

func (m *mockHardwareInspector) CPUPercent() (float64, error) {
	return m.cpuPercent, nil
}

func (m *mockHardwareInspector) CPUTemperature() (*float64, error) {
	return m.cpuTemp, nil
}

func (m *mockHardwareInspector) VirtualMemory() (*mem.VirtualMemoryStat, error) {
	return &mem.VirtualMemoryStat{
		Total:       m.totalRAM,
		Used:        m.usedRAM,
		UsedPercent: m.usedRAMPct,
	}, nil
}

func (m *mockHardwareInspector) NetIOCounters() (uint64, uint64, error) {
	return m.rxBytes, m.txBytes, nil
}

func (m *mockHardwareInspector) Partitions() ([]disk.PartitionStat, error) {
	return m.partitions, nil
}

func (m *mockHardwareInspector) DiskUsage(path string) (*disk.UsageStat, error) {
	if u, ok := m.diskUsages[path]; ok {
		return u, nil
	}
	return &disk.UsageStat{}, nil
}

func (m *mockHardwareInspector) Hostname() (string, error) {
	return m.hostnameStr, nil
}

func TestDiskFilter_Whitelisted(t *testing.T) {
	allowed := []string{"ext4", "xfs", "btrfs", "zfs", "ntfs", "vfat", "fat32", "apfs", "EXT4", "NTFS", " btrfs "}
	for _, fs := range allowed {
		if !collector.IsWhitelistedFilesystem(fs) {
			t.Errorf("expected filesystem %q to be allowed, but was rejected", fs)
		}
	}

	rejected := []string{"tmpfs", "devtmpfs", "overlay", "squashfs", "proc", "sys", "fuse", "autofs", "cgroup", "ramfs"}
	for _, fs := range rejected {
		if collector.IsWhitelistedFilesystem(fs) {
			t.Errorf("expected filesystem %q to be rejected, but was allowed", fs)
		}
	}
}

func TestCollector_CollectionAndNetworkDelta(t *testing.T) {
	temp := 52.3
	inspector := &mockHardwareInspector{
		cpuPercent:  35.5,
		cpuTemp:     &temp,
		totalRAM:    16000000000,
		usedRAM:     8000000000,
		usedRAMPct:  50.0,
		rxBytes:     1000000,
		txBytes:     500000,
		hostnameStr: "node-alpha",
		partitions: []disk.PartitionStat{
			{Mountpoint: "/", Fstype: "ext4"},
			{Mountpoint: "/boot/efi", Fstype: "vfat"},
			{Mountpoint: "/run", Fstype: "tmpfs"},         // Must be ignored
			{Mountpoint: "/sys/fs/cgroup", Fstype: "sys"}, // Must be ignored
		},
		diskUsages: map[string]*disk.UsageStat{
			"/": {
				Total:       500000000000,
				Free:        300000000000,
				UsedPercent: 40.0,
			},
			"/boot/efi": {
				Total:       500000000,
				Free:        450000000,
				UsedPercent: 10.0,
			},
		},
	}

	c := collector.NewCollector("test-machine-id-1234", inspector)

	// Tick 1: Network rates should start at 0
	frame1, err := c.Collect()
	if err != nil {
		t.Fatalf("unexpected collect error on tick 1: %v", err)
	}

	if frame1.GetMachineId() != "test-machine-id-1234" {
		t.Errorf("expected machine_id test-machine-id-1234, got %s", frame1.GetMachineId())
	}
	if frame1.GetHostname() != "node-alpha" {
		t.Errorf("expected hostname node-alpha, got %s", frame1.GetHostname())
	}
	if frame1.GetCpu().GetTotalUsagePercent() != 35.5 {
		t.Errorf("expected CPU 35.5, got %v", frame1.GetCpu().GetTotalUsagePercent())
	}
	if frame1.GetCpu().TemperatureC == nil || *frame1.GetCpu().TemperatureC != 52.3 {
		t.Errorf("expected temperature 52.3, got %v", frame1.GetCpu().TemperatureC)
	}
	if frame1.GetNetwork().GetRxBytesPerSec() != 0 || frame1.GetNetwork().GetTxBytesPerSec() != 0 {
		t.Errorf("expected initial network rate 0, got rx=%d tx=%d",
			frame1.GetNetwork().GetRxBytesPerSec(), frame1.GetNetwork().GetTxBytesPerSec())
	}

	// Verify disk filtering: only "/" (ext4) and "/boot/efi" (vfat)
	if len(frame1.GetDisks()) != 2 {
		t.Fatalf("expected 2 whitelisted disks, got %d", len(frame1.GetDisks()))
	}
	for _, d := range frame1.GetDisks() {
		if d.FsType == "tmpfs" || d.FsType == "sys" {
			t.Errorf("pseudo filesystem %s leaked into metrics!", d.FsType)
		}
	}

	// Tick 2: Advance network counters
	time.Sleep(100 * time.Millisecond) // brief sleep for time delta
	inspector.rxBytes = 1100000        // +100,000 bytes
	inspector.txBytes = 550000         // +50,000 bytes

	frame2, err := c.Collect()
	if err != nil {
		t.Fatalf("unexpected collect error on tick 2: %v", err)
	}

	if frame2.GetNetwork().GetRxBytesPerSec() == 0 {
		t.Errorf("expected non-zero rx rate on tick 2")
	}
	if frame2.GetNetwork().GetTxBytesPerSec() == 0 {
		t.Errorf("expected non-zero tx rate on tick 2")
	}
}

func TestCollector_MissingTemperatureGraceful(t *testing.T) {
	inspector := &mockHardwareInspector{
		cpuPercent:  10.0,
		cpuTemp:     nil, // Thermal sensors absent (virtual machine)
		totalRAM:    8000000000,
		usedRAM:     2000000000,
		usedRAMPct:  25.0,
		hostnameStr: "vm-node",
	}

	c := collector.NewCollector("vm-machine-uuid", inspector)
	frame, err := c.Collect()
	if err != nil {
		t.Fatalf("unexpected collect error: %v", err)
	}

	if frame.GetCpu() == nil {
		t.Fatal("expected CPU metrics to be present")
	}
	if frame.GetCpu().TemperatureC != nil {
		t.Errorf("expected nil TemperatureC on VM, got %v", *frame.GetCpu().TemperatureC)
	}
}

func TestCollector_RealSystemIntegration(t *testing.T) {
	c := collector.NewCollector("real-machine-test", nil)
	frame, err := c.Collect()
	if err != nil {
		t.Fatalf("unexpected error running collector on real system: %v", err)
	}

	if frame.GetHostname() == "" {
		t.Errorf("expected non-empty hostname")
	}
	if frame.GetMemory().GetTotalBytes() == 0 {
		t.Errorf("expected non-zero total RAM bytes")
	}
	t.Logf("Collected frame from real host: hostname=%s, cpu=%.2f%%, mem=%.2f%%, disks=%d",
		frame.GetHostname(),
		frame.GetCpu().GetTotalUsagePercent(),
		frame.GetMemory().GetUsagePercent(),
		len(frame.GetDisks()),
	)
}
