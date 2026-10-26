# ancymon-agent

Moduł agenta stacji roboczej (Host Agent) w języku Go dla systemów Linux i Windows.

## Kluczowe Cechy
- **Statyczna kompilacja**: Kompilacja do pojedynczego pliku wykonywalnego bez zewnętrznych zależności.
- **Wieloplatformowa usługa**: Wsparcie dla `systemd` (Linux) oraz `Windows Service` (Windows) przez `kardianos/service`.
- **Zbieranie metryk (1 Hz)**: CPU (zagregowane zużycie, temperatura), RAM, Network I/O (delta bajtów/s), dyski z białą listą systemów plików (`ext4`, `xfs`, `btrfs`, `zfs`, `ntfs`, `vfat`, `fat32`, `apfs`).
- **Bufor offline WAL**: Rotowane pliki 1 MB w `./buffer/` z limitem 50 MB, eksmisją FIFO i chronologicznym odtwarzaniem.
- **Klient gRPC**: HTTP/2 streaming z keepalive (30s ping, 10s timeout, permit without stream) i autoryzacją PSK Bearer.

## Odpowiedzialny Agent AI
- **`ancymon-agent-engineer`**
