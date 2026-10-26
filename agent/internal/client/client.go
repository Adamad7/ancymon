package client

import (
	"context"
	"crypto/tls"
	"crypto/x509"
	"errors"
	"fmt"
	"os"
	"time"

	ancymonproto "ancymon/proto"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials"
	"google.golang.org/grpc/credentials/insecure"
	"google.golang.org/grpc/keepalive"
	"google.golang.org/grpc/metadata"
)

// Config encapsulates connection and authentication parameters for the gRPC client.
type Config struct {
	ServerAddress string
	AuthToken     string
	TLSCAPath     string
	Insecure      bool
}

// TokenAuth implements credentials.PerRPCCredentials for Pre-Shared Key (PSK) authentication.
type TokenAuth struct {
	token      string
	requireTLS bool
}

// NewTokenAuth creates a PerRPCCredentials token authenticator.
func NewTokenAuth(token string, requireTLS bool) *TokenAuth {
	return &TokenAuth{
		token:      token,
		requireTLS: requireTLS,
	}
}

func (t *TokenAuth) GetRequestMetadata(ctx context.Context, uri ...string) (map[string]string, error) {
	return map[string]string{
		"authorization": "Bearer " + t.token,
	}, nil
}

func (t *TokenAuth) RequireTransportSecurity() bool {
	return t.requireTLS
}

// GRPCClient manages the gRPC HTTP/2 transport connection to ancymon-server.
type GRPCClient struct {
	conn       *grpc.ClientConn
	telemetry  ancymonproto.TelemetryServiceClient
	authToken  string
	requireTLS bool
}

// Dial connects to ancymon-server with keepalive framing and TLS/auth configured.
func Dial(cfg Config) (*GRPCClient, error) {
	if cfg.ServerAddress == "" {
		return nil, errors.New("server address must not be empty")
	}

	// Mandatory Keepalive Parameters:
	// - grpc.keepalive_time_ms = 30000 (30s ping)
	// - grpc.keepalive_timeout_ms = 10000 (10s timeout)
	// - grpc.keepalive_permit_without_stream = true
	kacp := keepalive.ClientParameters{
		Time:                30 * time.Second,
		Timeout:             10 * time.Second,
		PermitWithoutStream: true,
	}

	var dialOpts []grpc.DialOption
	dialOpts = append(dialOpts, grpc.WithKeepaliveParams(kacp))

	var transportCreds credentials.TransportCredentials
	requireTLS := !cfg.Insecure

	if cfg.Insecure {
		transportCreds = insecure.NewCredentials()
	} else {
		tlsConfig := &tls.Config{
			MinVersion: tls.VersionTLS12,
		}

		if cfg.TLSCAPath != "" {
			caCert, err := os.ReadFile(cfg.TLSCAPath)
			if err != nil {
				return nil, fmt.Errorf("failed to read root CA certificate at %s: %w", cfg.TLSCAPath, err)
			}
			caPool := x509.NewCertPool()
			if !caPool.AppendCertsFromPEM(caCert) {
				return nil, fmt.Errorf("failed to append root CA certificate from %s", cfg.TLSCAPath)
			}
			tlsConfig.RootCAs = caPool
		}

		transportCreds = credentials.NewTLS(tlsConfig)
	}

	dialOpts = append(dialOpts, grpc.WithTransportCredentials(transportCreds))

	// Attach Bearer Token authentication via PerRPCCredentials
	if cfg.AuthToken != "" {
		dialOpts = append(dialOpts, grpc.WithPerRPCCredentials(NewTokenAuth(cfg.AuthToken, requireTLS)))
	}

	conn, err := grpc.NewClient(cfg.ServerAddress, dialOpts...)
	if err != nil {
		return nil, fmt.Errorf("failed to create gRPC client for %s: %w", cfg.ServerAddress, err)
	}

	return &GRPCClient{
		conn:       conn,
		telemetry:  ancymonproto.NewTelemetryServiceClient(conn),
		authToken:  cfg.AuthToken,
		requireTLS: requireTLS,
	}, nil
}

// Close closes the gRPC client connection.
func (c *GRPCClient) Close() error {
	if c.conn != nil {
		return c.conn.Close()
	}
	return nil
}

// withAuthContext attaches the Bearer authorization token to outgoing metadata context.
func (c *GRPCClient) withAuthContext(ctx context.Context) context.Context {
	if c.authToken == "" {
		return ctx
	}
	return metadata.AppendToOutgoingContext(ctx, "authorization", "Bearer "+c.authToken)
}

// NewLiveStream opens a persistent Client Streaming call to ancymon-server.
func (c *GRPCClient) NewLiveStream(ctx context.Context) (ancymonproto.TelemetryService_StreamTelemetryClient, error) {
	authCtx := c.withAuthContext(ctx)
	return c.telemetry.StreamTelemetry(authCtx)
}

// SendBatch streams a slice of TelemetryFrame instances (e.g. from a WAL segment) and awaits TelemetryAck.
func (c *GRPCClient) SendBatch(ctx context.Context, frames []*ancymonproto.TelemetryFrame) (*ancymonproto.TelemetryAck, error) {
	if len(frames) == 0 {
		return &ancymonproto.TelemetryAck{
			Success:           true,
			AcknowledgedCount: 0,
		}, nil
	}

	stream, err := c.NewLiveStream(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to open stream for batch replay: %w", err)
	}

	for _, frame := range frames {
		if err := stream.Send(frame); err != nil {
			return nil, fmt.Errorf("failed to send frame during batch replay: %w", err)
		}
	}

	ack, err := stream.CloseAndRecv()
	if err != nil {
		return nil, fmt.Errorf("failed to receive ack for batch replay: %w", err)
	}

	if !ack.GetSuccess() {
		return ack, fmt.Errorf("server rejected batch replay: %s", ack.GetMessage())
	}

	return ack, nil
}
