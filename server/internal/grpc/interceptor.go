package grpc

import (
	"context"
	"crypto/subtle"
	"strings"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/metadata"
	"google.golang.org/grpc/status"
)

// AuthInterceptor enforces Pre-Shared Key (PSK) authentication via Bearer token.
type AuthInterceptor struct {
	expectedToken string
}

// NewAuthInterceptor creates an auth interceptor validating Bearer tokens against expectedToken.
func NewAuthInterceptor(expectedToken string) *AuthInterceptor {
	return &AuthInterceptor{
		expectedToken: expectedToken,
	}
}

// validateToken inspects gRPC incoming metadata for "authorization: Bearer <TOKEN>".
func (a *AuthInterceptor) validateToken(ctx context.Context) error {
	// If no auth token is configured on the server, permit all connections
	if a.expectedToken == "" {
		return nil
	}

	md, ok := metadata.FromIncomingContext(ctx)
	if !ok {
		return status.Error(codes.Unauthenticated, "metadata is missing from incoming request")
	}

	authHeaders := md.Get("authorization")
	if len(authHeaders) == 0 {
		return status.Error(codes.Unauthenticated, "authorization metadata header is missing")
	}

	authVal := strings.TrimSpace(authHeaders[0])
	const prefix = "Bearer "
	if !strings.HasPrefix(authVal, prefix) {
		return status.Error(codes.Unauthenticated, "authorization header must be in 'Bearer <token>' format")
	}

	token := strings.TrimSpace(authVal[len(prefix):])
	if subtle.ConstantTimeCompare([]byte(token), []byte(a.expectedToken)) != 1 {
		return status.Error(codes.Unauthenticated, "invalid pre-shared authentication token")
	}

	return nil
}

// UnaryInterceptor returns a gRPC unary interceptor for PSK auth validation.
func (a *AuthInterceptor) UnaryInterceptor() grpc.UnaryServerInterceptor {
	return func(ctx context.Context, req interface{}, info *grpc.UnaryServerInfo, handler grpc.UnaryHandler) (interface{}, error) {
		if err := a.validateToken(ctx); err != nil {
			return nil, err
		}
		return handler(ctx, req)
	}
}

// StreamInterceptor returns a gRPC stream interceptor for PSK auth validation.
func (a *AuthInterceptor) StreamInterceptor() grpc.StreamServerInterceptor {
	return func(srv interface{}, ss grpc.ServerStream, info *grpc.StreamServerInfo, handler grpc.StreamHandler) error {
		if err := a.validateToken(ss.Context()); err != nil {
			return err
		}
		return handler(srv, ss)
	}
}
