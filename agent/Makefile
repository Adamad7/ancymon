.PHONY: all build-linux build-windows build-all test vet clean

VERSION ?= 0.1.0
GIT_COMMIT ?= $(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")
BUILD_DATE ?= $(shell date -u +'%Y-%m-%dT%H:%M:%SZ')
LDFLAGS := -s -w -X main.Version=$(VERSION) -X main.GitCommit=$(GIT_COMMIT) -X main.BuildDate=$(BUILD_DATE)

BIN_DIR := bin

CMD_DIR := ./cmd/ancymon-agent

all: build-all

$(BIN_DIR):
	mkdir -p $(BIN_DIR)

build-linux: $(BIN_DIR)
	@echo "==> Building static binary for Linux (amd64)..."
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -trimpath -ldflags="$(LDFLAGS)" -o $(BIN_DIR)/ancymon-agent $(CMD_DIR)

build-windows: $(BIN_DIR)
	@echo "==> Building static binary for Windows (amd64)..."
	CGO_ENABLED=0 GOOS=windows GOARCH=amd64 go build -trimpath -ldflags="$(LDFLAGS)" -o $(BIN_DIR)/ancymon-agent.exe $(CMD_DIR)

build-all: build-linux build-windows

test:
	@echo "==> Running unit tests..."
	go test -v ./agent/...

test-race:
	@echo "==> Running unit tests with race detector..."
	go test -v -race ./agent/...

vet:
	@echo "==> Running go vet..."
	go vet ./agent/...

clean:
	@echo "==> Cleaning build artifacts..."
	rm -rf $(BIN_DIR)
