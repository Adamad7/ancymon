.PHONY: all build test run qr clean

BIN_DIR := bin
SERVER_BIN := $(BIN_DIR)/ancymon-server
QR_BIN := $(BIN_DIR)/ancymon-qr

all: test build

build:
	@mkdir -p $(BIN_DIR)
	@echo "Building ancymon-server..."
	go build -ldflags="-s -w" -o $(SERVER_BIN) ./cmd/ancymon-server
	@echo "Building ancymon-qr..."
	go build -ldflags="-s -w" -o $(QR_BIN) ./cmd/ancymon-qr
	@echo "Build complete: $(SERVER_BIN), $(QR_BIN)"

test:
	@echo "Running all server unit and integration tests..."
	go test -v -race ./...

run:
	@echo "Running ancymon-server..."
	go run ./cmd/ancymon-server -config ../server/config.example.yaml -qr -dev-ca

qr:
	@echo "Generating mobile pairing QR code..."
	@if [ -f ../deploy/root.crt ]; then \
		go run ./cmd/ancymon-qr -ca ../deploy/root.crt; \
	else \
		go run ./cmd/ancymon-qr -dev-ca; \
	fi

clean:
	@echo "Cleaning binaries..."
	rm -rf $(BIN_DIR)
