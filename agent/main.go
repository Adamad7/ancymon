package main

import (
	"flag"
	"fmt"
	"os"

	"ancymon/agent/internal/service"
)

func main() {
	configFlag := flag.String("config", "", "Path to ancymon-agent config.yaml")
	versionFlag := flag.Bool("version", false, "Print version information and exit")

	flag.Parse()

	if *versionFlag {
		fmt.Println("ancymon-agent v0.1.0")
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
