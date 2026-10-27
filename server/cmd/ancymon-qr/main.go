package main

import (
	"ancymon/server/internal/config"
	"ancymon/server/internal/qr"
	"flag"
	"fmt"
	"log"
	"os"
	"path/filepath"
)

func main() {
	configPath := flag.String("config", "", "Path to YAML configuration file")
	ipFlag := flag.String("ip", "", "Server IP or hostname override")
	portFlag := flag.Int("port", 0, "Ingress port override (default 443)")
	tokenFlag := flag.String("token", "", "Pre-shared key (PSK) token override")
	caFlag := flag.String("ca", "", "Path to Caddy root CA certificate override")
	devCA := flag.Bool("dev-ca", false, "Generate an ephemeral ECDSA P-256 CA certificate for testing")
	flag.Parse()

	cfg, err := config.LoadConfig(*configPath)
	if err != nil {
		log.Printf("[Warning] Could not load config: %v (using defaults)", err)
		cfg = config.DefaultConfig()
	}

	ip := cfg.Server.PublicIP
	if *ipFlag != "" {
		ip = *ipFlag
	}

	port := cfg.Server.PublicPort
	if *portFlag > 0 {
		port = *portFlag
	}

	token := cfg.Server.AuthToken
	if *tokenFlag != "" {
		token = *tokenFlag
	}

	caPath := cfg.Server.CaCertPath
	if *caFlag != "" {
		caPath = *caFlag
	}

	var caBase64 string
	if *devCA {
		_, derBase64, err := qr.GenerateDevECDSAKeyPair()
		if err != nil {
			log.Fatalf("Failed to generate dev ECDSA CA: %v", err)
		}
		caBase64 = derBase64
		fmt.Println("[Note] Using generated ephemeral ECDSA P-256 CA certificate.")
	} else {
		// Attempt finding CA certificate in configured and standard paths
		foundPath := findCACert(caPath)
		if foundPath == "" {
			fmt.Fprintf(os.Stderr, "Error: CA certificate not found at %q.\n", caPath)
			fmt.Fprintln(os.Stderr, "Provide a valid certificate path with -ca, or use -dev-ca for development.")
			os.Exit(1)
		}

		stripped, err := qr.ReadAndStripCACert(foundPath)
		if err != nil {
			log.Fatalf("Failed to read and strip CA certificate: %v", err)
		}
		caBase64 = stripped
		fmt.Printf("[Info] Loaded Root CA from %s\n", foundPath)
	}

	payloadJSON, err := qr.GeneratePairingJSON(ip, port, token, caBase64)
	if err != nil {
		log.Fatalf("Failed to build pairing payload: %v", err)
	}

	qrArt, err := qr.RenderTerminalQR(payloadJSON)
	if err != nil {
		log.Fatalf("Failed to render QR code: %v", err)
	}

	fmt.Println("\n=======================================================")
	fmt.Println("             AncyMon Mobile Pairing QR Code            ")
	fmt.Println("=======================================================")
	fmt.Println(qrArt)
	fmt.Println("-------------------------------------------------------")
	fmt.Printf("Server Host: %s:%d\n", ip, port)
	fmt.Printf("PSK Token:   %s\n", token)
	fmt.Println("Payload JSON:")
	fmt.Println(payloadJSON)
	fmt.Println("=======================================================")
}

func findCACert(preferredPath string) string {
	candidates := []string{
		preferredPath,
		"/data/caddy/pki/authorities/local/root.crt",
		filepath.Join(os.Getenv("HOME"), ".local/share/caddy/pki/authorities/local/root.crt"),
		"deploy/root.crt",
	}

	for _, p := range candidates {
		if p == "" {
			continue
		}
		if fi, err := os.Stat(p); err == nil && !fi.IsDir() {
			return p
		}
	}

	return ""
}
