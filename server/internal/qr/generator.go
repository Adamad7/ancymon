package qr

import (
	"crypto/ecdsa"
	"crypto/elliptic"
	"crypto/rand"
	"crypto/x509"
	"crypto/x509/pkix"
	"encoding/base64"
	"encoding/json"
	"encoding/pem"
	"fmt"
	"math/big"
	"os"
	"strings"
	"time"

	"github.com/skip2/go-qrcode"
)

// PairingPayload matches graphql/pairing.schema.json
type PairingPayload struct {
	IP    string `json:"ip"`
	Port  int    `json:"port"`
	Token string `json:"token"`
	CA    string `json:"ca"`
}

// GeneratePairingJSON constructs the minified JSON string for the pairing QR code.
func GeneratePairingJSON(ip string, port int, token, caRawBase64 string) (string, error) {
	if ip == "" {
		ip = "127.0.0.1"
	}
	if port <= 0 {
		port = 443
	}
	if token == "" {
		return "", fmt.Errorf("token cannot be empty")
	}
	if caRawBase64 == "" {
		return "", fmt.Errorf("ca certificate cannot be empty")
	}

	payload := PairingPayload{
		IP:    strings.TrimSpace(ip),
		Port:  port,
		Token: strings.TrimSpace(token),
		CA:    strings.TrimSpace(caRawBase64),
	}

	bytes, err := json.Marshal(payload)
	if err != nil {
		return "", fmt.Errorf("failed to marshal pairing payload: %w", err)
	}

	return string(bytes), nil
}

// ReadAndStripCACert reads a PEM or DER certificate file and returns the stripped raw Base64 DER string.
func ReadAndStripCACert(path string) (string, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return "", fmt.Errorf("failed to read certificate file %q: %w", path, err)
	}

	return StripPEMCertificate(data)
}

// StripPEMCertificate extracts the raw Base64 DER string from PEM or raw Base64 certificate bytes,
// stripping "-----BEGIN CERTIFICATE-----", "-----END CERTIFICATE-----", spaces, and newlines.
func StripPEMCertificate(pemData []byte) (string, error) {
	// First attempt standard PEM block decoding
	block, _ := pem.Decode(pemData)
	if block != nil && len(block.Bytes) > 0 {
		// Validate that it's a valid x509 certificate
		if _, err := x509.ParseCertificate(block.Bytes); err != nil {
			return "", fmt.Errorf("invalid x509 certificate: %w", err)
		}
		return base64.StdEncoding.EncodeToString(block.Bytes), nil
	}

	// If not standard PEM block, attempt stripping headers/whitespace manually
	str := string(pemData)
	str = strings.ReplaceAll(str, "-----BEGIN CERTIFICATE-----", "")
	str = strings.ReplaceAll(str, "-----END CERTIFICATE-----", "")
	str = strings.ReplaceAll(str, "\r", "")
	str = strings.ReplaceAll(str, "\n", "")
	str = strings.ReplaceAll(str, " ", "")
	str = strings.TrimSpace(str)

	// Verify decoding
	derBytes, err := base64.StdEncoding.DecodeString(str)
	if err != nil {
		return "", fmt.Errorf("certificate data is not valid base64 DER: %w", err)
	}

	if _, err := x509.ParseCertificate(derBytes); err != nil {
		return "", fmt.Errorf("decoded DER data is not a valid x509 certificate: %w", err)
	}

	return str, nil
}

// RenderTerminalQR renders a compact ASCII / Unicode half-block QR code for the terminal.
func RenderTerminalQR(payload string) (string, error) {
	qr, err := qrcode.New(payload, qrcode.Medium)
	if err != nil {
		return "", fmt.Errorf("failed to encode QR code: %w", err)
	}

	// ToSmallString(false) renders compact 2-in-1 Unicode half-blocks (▀, ▄, █, ' ')
	return qr.ToSmallString(false), nil
}

// GenerateDevECDSAKeyPair creates a self-signed ECDSA P-256 certificate for testing or initial dev setup.
func GenerateDevECDSAKeyPair() (certPEM []byte, certBase64DER string, err error) {
	priv, err := ecdsa.GenerateKey(elliptic.P256(), rand.Reader)
	if err != nil {
		return nil, "", fmt.Errorf("failed to generate ECDSA key: %w", err)
	}

	serialNumber, err := rand.Int(rand.Reader, new(big.Int).Lsh(big.NewInt(1), 128))
	if err != nil {
		return nil, "", fmt.Errorf("failed to generate serial number: %w", err)
	}

	template := x509.Certificate{
		SerialNumber: serialNumber,
		Subject: pkix.Name{
			CommonName:   "AncyMon Internal ECDSA Root CA",
			Organization: []string{"AncyMon Development"},
		},
		NotBefore:             time.Now().Add(-1 * time.Hour),
		NotAfter:              time.Now().Add(10 * 365 * 24 * time.Hour),
		KeyUsage:              x509.KeyUsageCertSign | x509.KeyUsageCRLSign | x509.KeyUsageDigitalSignature,
		BasicConstraintsValid: true,
		IsCA:                  true,
	}

	derBytes, err := x509.CreateCertificate(rand.Reader, &template, &template, &priv.PublicKey, priv)
	if err != nil {
		return nil, "", fmt.Errorf("failed to create certificate: %w", err)
	}

	pemBlock := pem.EncodeToMemory(&pem.Block{Type: "CERTIFICATE", Bytes: derBytes})
	base64DER := base64.StdEncoding.EncodeToString(derBytes)

	return pemBlock, base64DER, nil
}
