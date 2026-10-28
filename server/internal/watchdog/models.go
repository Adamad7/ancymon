package watchdog

import (
	ancymonproto "ancymon/proto"
	"time"
)

// MachineStatus constants matching GraphQL schema
const (
	StatusOnline  = "ONLINE"
	StatusOffline = "OFFLINE"
)

// MachineSummary corresponds to the GraphQL MachineSummary type for FleetSummary subscriptions.
type MachineSummary struct {
	MachineID            string   `json:"machineId"`
	Hostname             string   `json:"hostname"`
	Status               string   `json:"status"`
	LastSeenTimestamp    int64    `json:"lastSeenTimestamp"`
	CpuUsagePercent      *float64 `json:"cpuUsagePercent,omitempty"`
	CpuTemperatureC      *float64 `json:"cpuTemperatureC,omitempty"`
	NetworkRxBytesPerSec *float64 `json:"networkRxBytesPerSec,omitempty"`
	NetworkTxBytesPerSec *float64 `json:"networkTxBytesPerSec,omitempty"`
}

// MachineDetail corresponds to the GraphQL MachineDetail type for MachineMetrics subscriptions.
type MachineDetail struct {
	MachineID string                 `json:"machineId"`
	Hostname  string                 `json:"hostname"`
	Status    string                 `json:"status"`
	Timestamp int64                  `json:"timestamp"`
	Cpu       DetailedCpuMetrics     `json:"cpu"`
	Memory    DetailedMemoryMetrics  `json:"memory"`
	Network   DetailedNetworkMetrics `json:"network"`
	Disks     []DiskPartitionInfo    `json:"disks"`
}

// DetailedCpuMetrics holds processor utilization and thermal data.
type DetailedCpuMetrics struct {
	TotalUsagePercent float64  `json:"totalUsagePercent"`
	TemperatureC      *float64 `json:"temperatureC,omitempty"`
}

// DetailedMemoryMetrics holds RAM volume and utilization data.
type DetailedMemoryMetrics struct {
	TotalBytes   float64 `json:"totalBytes"`
	UsedBytes    float64 `json:"usedBytes"`
	UsagePercent float64 `json:"usagePercent"`
}

// DetailedNetworkMetrics holds network interface throughput data.
type DetailedNetworkMetrics struct {
	RxBytesPerSec float64 `json:"rxBytesPerSec"`
	TxBytesPerSec float64 `json:"txBytesPerSec"`
}

// DiskPartitionInfo holds filesystem mount and storage metrics.
type DiskPartitionInfo struct {
	MountPoint   string  `json:"mountPoint"`
	FsType       string  `json:"fsType"`
	TotalBytes   float64 `json:"totalBytes"`
	FreeBytes    float64 `json:"freeBytes"`
	UsagePercent float64 `json:"usagePercent"`
}

// MachineRecord is the in-memory cache representation of a monitored host.
type MachineRecord struct {
	MachineID   string                       `json:"machine_id"`
	Hostname    string                       `json:"hostname"`
	Status      string                       `json:"status"`
	LastSeen    time.Time                    `json:"last_seen"`
	LatestFrame *ancymonproto.TelemetryFrame `json:"latest_frame,omitempty"`
}

// ToMachineDetail converts a MachineRecord to a GraphQL MachineDetail model.
func (r *MachineRecord) ToMachineDetail() *MachineDetail {
	if r == nil {
		return nil
	}

	detail := &MachineDetail{
		MachineID: r.MachineID,
		Hostname:  r.Hostname,
		Status:    r.Status,
		Timestamp: r.LastSeen.Unix(),
		Disks:     make([]DiskPartitionInfo, 0),
	}

	if f := r.LatestFrame; f != nil {
		if f.TimestampUnix > 0 {
			detail.Timestamp = f.TimestampUnix
		}
		if f.Cpu != nil {
			detail.Cpu = DetailedCpuMetrics{
				TotalUsagePercent: f.Cpu.TotalUsagePercent,
				TemperatureC:      f.Cpu.TemperatureC,
			}
		}
		if f.Memory != nil {
			detail.Memory = DetailedMemoryMetrics{
				TotalBytes:   float64(f.Memory.TotalBytes),
				UsedBytes:    float64(f.Memory.UsedBytes),
				UsagePercent: f.Memory.UsagePercent,
			}
		}
		if f.Network != nil {
			detail.Network = DetailedNetworkMetrics{
				RxBytesPerSec: float64(f.Network.RxBytesPerSec),
				TxBytesPerSec: float64(f.Network.TxBytesPerSec),
			}
		}
		for _, d := range f.Disks {
			if d != nil {
				detail.Disks = append(detail.Disks, DiskPartitionInfo{
					MountPoint:   d.MountPoint,
					FsType:       d.FsType,
					TotalBytes:   float64(d.TotalBytes),
					FreeBytes:    float64(d.FreeBytes),
					UsagePercent: d.UsagePercent,
				})
			}
		}
	}

	return detail
}

// ToMachineSummary converts a MachineRecord to a GraphQL MachineSummary model.
func (r *MachineRecord) ToMachineSummary() MachineSummary {
	sum := MachineSummary{
		MachineID:         r.MachineID,
		Hostname:          r.Hostname,
		Status:            r.Status,
		LastSeenTimestamp: r.LastSeen.Unix(),
	}

	if f := r.LatestFrame; f != nil {
		if f.Cpu != nil {
			cpuVal := f.Cpu.TotalUsagePercent
			sum.CpuUsagePercent = &cpuVal
			sum.CpuTemperatureC = f.Cpu.TemperatureC
		}
		if f.Network != nil {
			rxVal := float64(f.Network.RxBytesPerSec)
			txVal := float64(f.Network.TxBytesPerSec)
			sum.NetworkRxBytesPerSec = &rxVal
			sum.NetworkTxBytesPerSec = &txVal
		}
	}

	return sum
}
