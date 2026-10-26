package collector

import (
	"fmt"
	"math"
	"os"
	"strings"
	"sync"
	"time"

	ancymonproto "ancymon/proto"

	"github.com/shirou/gopsutil/v3/cpu"
	"github.com/shirou/gopsutil/v3/disk"
	"github.com/shirou/gopsutil/v3/host"
	"github.com/shirou/gopsutil/v3/mem"
	"github.com/shirou/gopsutil/v3/net"
)

// HardwareInspector abstracts hardware metrics calls for testability.
type HardwareInspector interface {
	CPUPercent() (float64, error)
	CPUTemperature() (*float64, error)
	VirtualMemory() (*mem.VirtualMemoryStat, error)
	NetIOCounters() (uint64, uint64, error)
	Partitions() ([]disk.PartitionStat, error)
	DiskUsage(path string) (*disk.UsageStat, error)
	Hostname() (string, error)
}

// DefaultHardwareInspector implements HardwareInspector using gopsutil and standard OS calls.
type DefaultHardwareInspector struct{}

func (d *DefaultHardwareInspector) CPUPercent() (float64, error) {
	// Interval 0 gives instantaneous percentage since last call (or boot)
	percents, err := cpu.Percent(0, false)
	if err != nil {
		return 0, err
	}
	if len(percents) == 0 {
		return 0, nil
	}
	val := percents[0]
	if math.IsNaN(val) || math.IsInf(val, 0) || val < 0 {
		val = 0
	} else if val > 100 {
		val = 100
	}
	return math.Round(val*100) / 100, nil
}

func (d *DefaultHardwareInspector) CPUTemperature() (*float64, error) {
	temps, err := host.SensorsTemperatures()
	if err != nil {
		return nil, nil // Silently return nil if sensors are unreadable (e.g. virtual machine)
	}

	var candidates []float64
	var prioritizedTemp *float64

	for _, t := range temps {
		if t.Temperature <= 0 || t.Temperature > 140 {
			continue
		}
		key := strings.ToLower(t.SensorKey)
		// Prioritize package or coretemp
		if strings.Contains(key, "package") || strings.Contains(key, "tctl") || strings.Contains(key, "cpu") {
			tempVal := math.Round(t.Temperature*10) / 10
			prioritizedTemp = &tempVal
			break
		}
		candidates = append(candidates, t.Temperature)
	}

	if prioritizedTemp != nil {
		return prioritizedTemp, nil
	}
	if len(candidates) > 0 {
		avg := candidates[0]
		rounded := math.Round(avg*10) / 10
		return &rounded, nil
	}

	return nil, nil
}

func (d *DefaultHardwareInspector) VirtualMemory() (*mem.VirtualMemoryStat, error) {
	return mem.VirtualMemory()
}

func (d *DefaultHardwareInspector) NetIOCounters() (uint64, uint64, error) {
	counters, err := net.IOCounters(false)
	if err != nil {
		return 0, 0, err
	}
	if len(counters) == 0 {
		return 0, 0, nil
	}
	return counters[0].BytesRecv, counters[0].BytesSent, nil
}

func (d *DefaultHardwareInspector) Partitions() ([]disk.PartitionStat, error) {
	return disk.Partitions(true)
}

func (d *DefaultHardwareInspector) DiskUsage(path string) (*disk.UsageStat, error) {
	return disk.Usage(path)
}

func (d *DefaultHardwareInspector) Hostname() (string, error) {
	h, err := os.Hostname()
	if err != nil {
		return "unknown-host", nil
	}
	return h, nil
}

// Collector coordinates 1 Hz hardware metric collection.
type Collector struct {
	mu        sync.Mutex
	machineID string
	inspector HardwareInspector

	lastNetRx   uint64
	lastNetTx   uint64
	lastNetTime time.Time
}

// NewCollector constructs a new telemetry collector for the host machine.
func NewCollector(machineID string, inspector HardwareInspector) *Collector {
	if inspector == nil {
		inspector = &DefaultHardwareInspector{}
	}
	return &Collector{
		machineID: machineID,
		inspector: inspector,
	}
}

// Collect samples the hardware metrics and returns a populated TelemetryFrame.
func (c *Collector) Collect() (*ancymonproto.TelemetryFrame, error) {
	c.mu.Lock()
	defer c.mu.Unlock()

	now := time.Now()
	nowUnix := now.Unix()

	hostname, err := c.inspector.Hostname()
	if err != nil {
		hostname = "unknown-host"
	}

	// 1. CPU Metrics
	cpuUsage, err := c.inspector.CPUPercent()
	if err != nil {
		cpuUsage = 0
	}
	cpuTemp, _ := c.inspector.CPUTemperature()

	cpuMetrics := &ancymonproto.CpuMetrics{
		TotalUsagePercent: cpuUsage,
		TemperatureC:      cpuTemp,
	}

	// 2. Memory Metrics
	vm, err := c.inspector.VirtualMemory()
	if err != nil {
		return nil, fmt.Errorf("failed to collect memory metrics: %w", err)
	}
	memMetrics := &ancymonproto.MemoryMetrics{
		TotalBytes:   vm.Total,
		UsedBytes:    vm.Used,
		UsagePercent: math.Round(vm.UsedPercent*100) / 100,
	}

	// 3. Network Metrics (Rate in bytes/sec)
	currRx, currTx, err := c.inspector.NetIOCounters()
	var rxRate, txRate uint64
	if err == nil {
		if !c.lastNetTime.IsZero() {
			deltaSec := now.Sub(c.lastNetTime).Seconds()
			if deltaSec > 0 {
				if currRx >= c.lastNetRx {
					rxRate = uint64(float64(currRx-c.lastNetRx) / deltaSec)
				}
				if currTx >= c.lastNetTx {
					txRate = uint64(float64(currTx-c.lastNetTx) / deltaSec)
				}
			}
		}
		c.lastNetRx = currRx
		c.lastNetTx = currTx
		c.lastNetTime = now
	}
	netMetrics := &ancymonproto.NetworkMetrics{
		RxBytesPerSec: rxRate,
		TxBytesPerSec: txRate,
	}

	// 4. Storage Metrics (Whitelisted partitions)
	var diskMetrics []*ancymonproto.DiskPartitionMetrics
	partitions, err := c.inspector.Partitions()
	if err == nil {
		seenMounts := make(map[string]bool)
		for _, part := range partitions {
			if !IsWhitelistedFilesystem(part.Fstype) {
				continue
			}
			if seenMounts[part.Mountpoint] {
				continue
			}
			seenMounts[part.Mountpoint] = true

			usage, err := c.inspector.DiskUsage(part.Mountpoint)
			if err != nil {
				continue
			}

			diskMetrics = append(diskMetrics, &ancymonproto.DiskPartitionMetrics{
				MountPoint:   part.Mountpoint,
				FsType:       strings.ToLower(part.Fstype),
				TotalBytes:   usage.Total,
				FreeBytes:    usage.Free,
				UsagePercent: math.Round(usage.UsedPercent*100) / 100,
			})
		}
	}

	frame := &ancymonproto.TelemetryFrame{
		MachineId:     c.machineID,
		Hostname:      hostname,
		TimestampUnix: nowUnix,
		Cpu:           cpuMetrics,
		Memory:        memMetrics,
		Network:       netMetrics,
		Disks:         diskMetrics,
	}

	return frame, nil
}
