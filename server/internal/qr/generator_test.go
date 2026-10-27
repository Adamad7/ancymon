package qr

import (
	"crypto/x509"
	"encoding/base64"
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestQRGenerationAndStripping(t *testing.T) {
	pemBytes, base64DER, err := GenerateDevECDSAKeyPair()
	if err != nil {
		t.Fatalf("GenerateDevECDSAKeyPair failed: %v", err)
	}

	// 1. Strip PEM from memory
	stripped, err := StripPEMCertificate(pemBytes)
	if err != nil {
		t.Fatalf("StripPEMCertificate failed: %v", err)
	}
	if stripped != base64DER {
		t.Errorf("stripped string mismatch with expected base64 DER")
	}

	// 2. Strip PEM from file
	tmpDir := t.TempDir()
	certFile := filepath.Join(tmpDir, "root.crt")
	if err := os.WriteFile(certFile, pemBytes, 0600); err != nil {
		t.Fatalf("failed to write temp cert: %v", err)
	}

	readStripped, err := ReadAndStripCACert(certFile)
	if err != nil {
		t.Fatalf("ReadAndStripCACert failed: %v", err)
	}
	if readStripped != base64DER {
		t.Errorf("readStripped does not match base64DER")
	}

	// 3. Verify certificate is valid x509 ECDSA
	derBytes, err := base64.StdEncoding.DecodeString(readStripped)
	if err != nil {
		t.Fatalf("base64 decode failed: %v", err)
	}
	cert, err := x509.ParseCertificate(derBytes)
	if err != nil {
		t.Fatalf("ParseCertificate failed: %v", err)
	}
	if cert.PublicKeyAlgorithm != x509.ECDSA {
		t.Errorf("expected ECDSA public key, got %v", cert.PublicKeyAlgorithm)
	}

	// 4. Generate JSON payload
	payloadJSON, err := GeneratePairingJSON("192.168.1.100", 443, "my-secret-token", readStripped)
	if err != nil {
		t.Fatalf("GeneratePairingJSON failed: %v", err)
	}

	var payload PairingPayload
	if err := json.Unmarshal([]byte(payloadJSON), &payload); err != nil {
		t.Fatalf("failed to parse JSON pairing payload: %v", err)
	}

	if payload.IP != "192.168.1.100" || payload.Port != 443 || payload.Token != "my-secret-token" || payload.CA != readStripped {
		t.Errorf("payload mismatch: %+v", payload)
	}

	// 5. Render terminal QR code
	art, err := RenderTerminalQR(payloadJSON)
	if err != nil {
		t.Fatalf("RenderTerminalQR failed: %v", err)
	}
	if len(art) == 0 || !strings.Contains(art, "▄") && !strings.Contains(art, "█") && !strings.Contains(art, "▀") {
		t.Errorf("unexpected terminal QR rendering output:\n%s", art)
	}
}
