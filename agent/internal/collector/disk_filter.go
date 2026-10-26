package collector

import (
	"strings"
)

// AllowedFilesystems contains the strict whitelist of permissible physical/real filesystems.
// Virtual and pseudo filesystems (e.g., tmpfs, devtmpfs, overlay, squashfs, proc, sys) are explicitly excluded.
var AllowedFilesystems = map[string]struct{}{
	"ext4":  {},
	"xfs":   {},
	"btrfs": {},
	"zfs":   {},
	"ntfs":  {},
	"vfat":  {},
	"fat32": {},
	"apfs":  {},
}

// IsWhitelistedFilesystem verifies whether the given filesystem type matches the whitelist.
func IsWhitelistedFilesystem(fsType string) bool {
	normalized := strings.ToLower(strings.TrimSpace(fsType))
	_, ok := AllowedFilesystems[normalized]
	return ok
}
