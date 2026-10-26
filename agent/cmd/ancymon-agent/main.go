package main

import (
	"flag"
	"fmt"
	"os"

	"ancymon/agent/internal/service"
)

var (
	// Version is injected during static build via -ldflags
	Version   = "0.1.0"
	GitCommit = "development"
	BuildDate = "unknown"
)

func main() {
	configFlag := flag.String("config", "", "Path to ancymon-agent config.yaml")
	versionFlag := flag.Bool("version", false, "Print version information and exit")

	flag.Usage = func() {
		fmt.Fprintf(os.Stderr, "AncyMon Workstation Host Telemetry Agent v%s\n\n", Version)
		fmt.Fprintf(os.Stderr, "Usage:\n")
		fmt.Fprintf(os.Stderr, "  ancymon-agent [command] [flags]\n\n")
		fmt.Fprintf(os.Stderr, "Commands:\n")
		fmt.Fprintf(os.Stderr, "  run        Run agent in foreground/daemon mode (default)\n")
		fmt.Fprintf(os.Stderr, "  install    Install as OS service (systemd / Windows Service)\n")
		fmt.Fprintf(os.Stderr, "  uninstall  Remove OS service\n")
		fmt.Fprintf(os.Stderr, "  start      Start installed OS service\n")
		fmt.Fprintf(os.Stderr, "  stop       Stop installed OS service\n")
		fmt.Fprintf(os.Stderr, "  restart    Restart installed OS service\n")
		fmt.Fprintf(os.Stderr, "  status     Check installed OS service status\n\n")
		fmt.Fprintf(os.Stderr, "Flags:\n")
		flag.PrintDefaults()
	}

	flag.Parse()

	if *versionFlag {
		fmt.Printf("ancymon-agent v%s (commit: %s, built: %s)\n", Version, GitCommit, BuildDate)
		os.Exit(0)
	}

	action := "run"
	args := flag.Args()
	if len(args) > 0 {
		action = args[0]
	}

	if err := service.ExecuteAction(action, *configFlag); err != nil {
		fmt.Fprintf(os.Stderr, "Error executing %s: %v\n", action, err)
		os.Exit(1)
	}
}
