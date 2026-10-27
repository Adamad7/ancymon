package main

import (
	"ancymon/server/internal/config"
	srvgrpc "ancymon/server/internal/grpc"
	"ancymon/server/internal/graphql"
	"ancymon/server/internal/qr"
	"ancymon/server/internal/storage"
	"ancymon/server/internal/watchdog"
	"context"
	"flag"
	"fmt"
	"log"
	"net"
	"net/http"
	"os"
	"os/signal"
	"path/filepath"
	"syscall"
	"time"
)

func main() {
	configPath := flag.String("config", "", "Path to YAML configuration file")
	showQR := flag.Bool("qr", false, "Render terminal pairing QR code on startup")
	devCA := flag.Bool("dev-ca", false, "Generate an ephemeral ECDSA P-256 CA certificate for testing")
	flag.Parse()

	// 1. Load Server Configuration
	cfg, err := config.LoadConfig(*configPath)
	if err != nil {
		log.Printf("[Config] Warning: Failed to load config file: %v. Using defaults.", err)
		cfg = config.DefaultConfig()
	}

	log.Printf("[Config] gRPC Port: :%d | GraphQL Port: :%d | VM URL: %s",
		cfg.Server.GrpcPort, cfg.Server.GraphQLPort, cfg.VictoriaMetrics.URL)

	// 2. Initialize In-Memory Host Registry and Watchdog
	registry := watchdog.NewRegistry(nil)
	watchdogWorker := watchdog.NewWatchdog(
		registry,
		time.Duration(cfg.Watchdog.CheckIntervalSec)*time.Second,
		time.Duration(cfg.Watchdog.OfflineTimeoutSec)*time.Second,
	)

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	watchdogWorker.Start(ctx)

	// 3. Initialize VictoriaMetrics Writer & Querier
	writer := storage.NewWriter(
		cfg.VictoriaMetrics.URL,
		cfg.VictoriaMetrics.BatchSize,
		time.Duration(cfg.VictoriaMetrics.FlushIntervalMs)*time.Millisecond,
	)
	defer writer.Stop()

	querier := storage.NewQuerier(cfg.VictoriaMetrics.URL)

	// 4. Initialize gRPC Ingestion Engine
	grpcServer := srvgrpc.NewServer(registry, writer, cfg.Server.AuthToken)
	grpcLis, err := net.Listen("tcp", fmt.Sprintf(":%d", cfg.Server.GrpcPort))
	if err != nil {
		log.Fatalf("[gRPC] Failed to listen on port %d: %v", cfg.Server.GrpcPort, err)
	}

	go func() {
		log.Printf("[gRPC] Telemetry ingestion server listening on :%d (h2c)", cfg.Server.GrpcPort)
		if err := grpcServer.Serve(grpcLis); err != nil {
			log.Printf("[gRPC] Server terminated: %v", err)
		}
	}()

	// 5. Initialize GraphQL Engine (HTTP Queries & WebSocket Subscriptions)
	gqlHandler := graphql.NewHandler(registry, querier, cfg.Server.AuthToken)
	mux := http.NewServeMux()
	mux.Handle("/graphql", gqlHandler)
	mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte("OK"))
	})

	httpServer := &http.Server{
		Addr:         fmt.Sprintf(":%d", cfg.Server.GraphQLPort),
		Handler:      mux,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	go func() {
		log.Printf("[GraphQL] Mobile client API listening on :%d (HTTP/WS)", cfg.Server.GraphQLPort)
		if err := httpServer.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("[GraphQL] Server error: %v", err)
		}
	}()

	// 6. Optional: Render Terminal QR Code
	if *showQR {
		printPairingQR(cfg, *devCA)
	}

	// 7. Await termination signals for graceful shutdown
	sigCh := make(chan os.Signal, 1)
	signal.Notify(sigCh, os.Interrupt, syscall.SIGTERM)
	sig := <-sigCh
	log.Printf("[Server] Received shutdown signal: %v. Initiating graceful shutdown...", sig)

	// Graceful shutdown sequence
	grpcServer.GracefulStop()
	shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer shutdownCancel()
	_ = httpServer.Shutdown(shutdownCtx)

	log.Println("[Server] AncyMon server successfully stopped.")
}

func printPairingQR(cfg *config.Config, devCA bool) {
	var caBase64 string
	if devCA {
		_, derBase64, err := qr.GenerateDevECDSAKeyPair()
		if err == nil {
			caBase64 = derBase64
		}
	} else {
		candidates := []string{
			cfg.Server.CaCertPath,
			"/data/caddy/pki/authorities/local/root.crt",
			filepath.Join(os.Getenv("HOME"), ".local/share/caddy/pki/authorities/local/root.crt"),
			"deploy/root.crt",
		}
		for _, p := range candidates {
			if fi, err := os.Stat(p); err == nil && !fi.IsDir() {
				if stripped, err := qr.ReadAndStripCACert(p); err == nil {
					caBase64 = stripped
					break
				}
			}
		}
	}

	if caBase64 == "" {
		log.Println("[QR] Warning: Could not locate CA root certificate. Pair manually or pass -dev-ca.")
		return
	}

	payloadJSON, err := qr.GeneratePairingJSON(cfg.Server.PublicIP, cfg.Server.PublicPort, cfg.Server.AuthToken, caBase64)
	if err != nil {
		log.Printf("[QR] Error generating payload: %v", err)
		return
	}

	art, err := qr.RenderTerminalQR(payloadJSON)
	if err == nil {
		fmt.Println("\n=== AncyMon Mobile Pairing QR ===")
		fmt.Println(art)
		fmt.Printf("Pairing Host: %s:%d\n", cfg.Server.PublicIP, cfg.Server.PublicPort)
		fmt.Println("=================================")
	}
}
