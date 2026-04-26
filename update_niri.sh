#!/bin/bash

# Script to update niri from source on Ubuntu/Debian
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

NIRI_DIR="$HOME/niri"

if [ ! -d "$NIRI_DIR" ]; then
    print_error "niri source directory not found at $NIRI_DIR."
    print_error "Run install_niri.sh first to perform the initial build and install."
    exit 1
fi

print_status "Pulling latest niri source..."
cd "$NIRI_DIR"
git pull

print_status "Updating Rust toolchain..."
rustup update stable

print_status "Rebuilding niri with cargo..."
print_warning "This may take several minutes..."
cargo build --release

print_status "Installing updated niri binaries system-wide..."
sudo cp target/release/niri /usr/local/bin/niri
sudo cp resources/niri-session /usr/local/bin/niri-session
sudo chmod +x /usr/local/bin/niri /usr/local/bin/niri-session

print_status "niri updated successfully!"
print_status "Version: $(/usr/local/bin/niri --version 2>/dev/null || echo 'unknown')"
print_status "Restart your niri session to use the new build."
