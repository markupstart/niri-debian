#!/bin/bash

# Script to install niri dependencies and build from source on Ubuntu/Debian
set -e

echo "Starting niri installation process..."

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

install_dank_material_shell() {
    if ! grep -q "^ID=debian" /etc/os-release; then
        print_warning "Automated Dank Material Shell installation is currently configured only for Debian."
        print_warning "See https://danklinux.com/docs/dankmaterialshell/installation for your distribution's instructions."
        return
    fi

    . /etc/os-release

    case "$VERSION_CODENAME" in
        trixie)
            DMS_DISTRO="Debian_13"
            ;;
        testing)
            DMS_DISTRO="Debian_Testing"
            ;;
        sid|unstable)
            DMS_DISTRO="Debian_Unstable"
            ;;
        *)
            print_warning "No official Dank Material Shell repository mapping found for Debian codename '$VERSION_CODENAME'."
            print_warning "See https://danklinux.com/docs/dankmaterialshell/installation for manual setup instructions."
            return
            ;;
    esac

    print_status "Installing Dank Material Shell from the official Debian repository..."

    sudo mkdir -p /etc/apt/keyrings

    curl -fsSL "https://download.opensuse.org/repositories/home:/AvengeMedia:/danklinux/${DMS_DISTRO}/Release.key" |
        sudo gpg --dearmor -o /etc/apt/keyrings/danklinux.gpg
    echo "deb [signed-by=/etc/apt/keyrings/danklinux.gpg] https://download.opensuse.org/repositories/home:/AvengeMedia:/danklinux/${DMS_DISTRO}/ /" |
        sudo tee /etc/apt/sources.list.d/danklinux.list > /dev/null

    curl -fsSL "https://download.opensuse.org/repositories/home:/AvengeMedia:/dms/${DMS_DISTRO}/Release.key" |
        sudo gpg --dearmor -o /etc/apt/keyrings/avengemedia-dms.gpg
    echo "deb [signed-by=/etc/apt/keyrings/avengemedia-dms.gpg] https://download.opensuse.org/repositories/home:/AvengeMedia:/dms/${DMS_DISTRO}/ /" |
        sudo tee /etc/apt/sources.list.d/avengemedia-dms.list > /dev/null

    sudo DEBIAN_FRONTEND=noninteractive APT_LISTCHANGES_FRONTEND=none \
        apt-get update
    sudo DEBIAN_FRONTEND=noninteractive APT_LISTCHANGES_FRONTEND=none \
        apt-get install -y \
        -o Dpkg::Options::=--force-confdef \
        -o Dpkg::Options::=--force-confold \
        dms accountsservice ghostty

    print_status "Generating starter Dank Material Shell configuration..."
    dms setup

    print_status "Binding Dank Material Shell to the niri user service..."
    systemctl --user add-wants niri.service dms

    print_status "Dank Material Shell installed successfully!"
    print_status "DMS will start with niri through the user systemd session."
 }

# Check if running on Ubuntu or Debian
if ! grep -qE "Ubuntu|Debian" /etc/os-release; then
    print_error "This script is designed for Ubuntu/Debian. Please check your distribution."
    exit 1
fi

print_status "Installing dependencies for niri..."

# Install required packages for Ubuntu/Debian
sudo DEBIAN_FRONTEND=noninteractive APT_LISTCHANGES_FRONTEND=none \
    apt-get update
sudo DEBIAN_FRONTEND=noninteractive APT_LISTCHANGES_FRONTEND=none \
    apt-get install -y \
    -o Dpkg::Options::=--force-confdef \
    -o Dpkg::Options::=--force-confold \
    gcc \
    clang \
    libudev-dev \
    libgbm-dev \
    libxkbcommon-dev \
    libegl1-mesa-dev \
    libwayland-dev \
    libinput-dev \
    libdbus-1-dev \
    libsystemd-dev \
    libseat-dev \
    libpipewire-0.3-dev \
    libpango1.0-dev \
    libdisplay-info-dev \
    git \
    rustup

print_status "Dependencies installed successfully!"

# Check if Rust toolchain is already set up
if command -v rustc &> /dev/null; then
    print_status "Rust is already installed. Version: $(rustc --version)"
    read -p "Do you want to update Rust to the latest stable version? (y/n): " update_rust
    if [[ $update_rust =~ ^[Yy]$ ]]; then
        rustup update stable
    fi
else
    print_status "Setting up Rust toolchain via rustup..."
    # Initialize rustup and install stable toolchain
    rustup default stable
fi

# Ensure we have the latest stable Rust
print_status "Ensuring latest stable Rust toolchain..."
rustup update stable

print_status "Rust version: $(rustc --version)"

if command -v rmpc &> /dev/null; then
    print_status "rmpc is already installed. Skipping cargo install."
else
    print_status "Installing rmpc with cargo..."
    cargo install rmpc --locked
fi

if command -v yazi &> /dev/null && command -v ya &> /dev/null; then
    print_status "yazi is already installed. Skipping cargo install."
else
    print_status "Installing yazi with cargo..."
    cargo install --force yazi-build
fi

# Clone niri repository
NIRI_DIR="$HOME/niri"
if [ -d "$NIRI_DIR" ]; then
    print_warning "niri directory already exists at $NIRI_DIR"
    read -p "Do you want to remove it and clone fresh? (y/n): " remove_existing
    if [[ $remove_existing =~ ^[Yy]$ ]]; then
        rm -rf "$NIRI_DIR"
    else
        print_status "Using existing niri directory. Pulling latest changes..."
        cd "$NIRI_DIR"
        git pull
    fi
fi

if [ ! -d "$NIRI_DIR" ]; then
    print_status "Cloning niri repository..."
    git clone https://github.com/niri-wm/niri.git "$NIRI_DIR"
    cd "$NIRI_DIR"
else
    cd "$NIRI_DIR"
fi

print_status "Building niri with cargo..."
print_warning "This may take several minutes..."

# Build niri (using release profile for performance)
cargo build --release

if [ $? -eq 0 ]; then
    print_status "niri built successfully!"
    print_status "Binary location: $NIRI_DIR/target/release/niri"
    
    echo ""
    print_status "Next steps for manual installation:"
    echo "1. Copy files to system directories (requires sudo):"
    echo "   sudo cp target/release/niri /usr/local/bin/"
    echo "   sudo cp resources/niri-session /usr/local/bin/"
    echo "   sudo cp resources/niri.desktop /usr/local/share/wayland-sessions/"
    echo "   sudo cp resources/niri-portals.conf /usr/local/share/xdg-desktop-portal/"
    echo "   sudo cp resources/niri.service /etc/systemd/user/"
    echo "   sudo cp resources/niri-shutdown.target /etc/systemd/user/"
    echo ""
    echo "2. Create necessary directories if they don't exist:"
    echo "   sudo mkdir -p /usr/local/share/wayland-sessions/"
    echo "   sudo mkdir -p /usr/local/share/xdg-desktop-portal/"
    echo ""
    
    read -p "Do you want to install niri system-wide now? (y/n): " install_system
    if [[ $install_system =~ ^[Yy]$ ]]; then
        print_status "Installing niri system-wide..."
        
        # Create directories
        sudo mkdir -p /usr/local/share/wayland-sessions/
        sudo mkdir -p /usr/local/share/xdg-desktop-portal/
        
        # Copy files
        sudo cp target/release/niri /usr/local/bin/
        sudo cp resources/niri-session /usr/local/bin/
        sudo cp resources/niri.desktop /usr/local/share/wayland-sessions/
        sudo cp resources/niri-portals.conf /usr/local/share/xdg-desktop-portal/
        sudo cp resources/niri.service /etc/systemd/user/
        sudo cp resources/niri-shutdown.target /etc/systemd/user/
        
        # Fix the niri.service file to point to the correct binary path
        print_status "Updating niri.service to use /usr/local/bin/niri..."
        sudo sed -i 's|ExecStart=/usr/bin/niri|ExecStart=/usr/local/bin/niri|g' /etc/systemd/user/niri.service
        
        # Make binaries executable
        sudo chmod +x /usr/local/bin/niri
        sudo chmod +x /usr/local/bin/niri-session
        
        print_status "niri installed system-wide successfully!"
        print_status "You can now log out and select 'niri' from your display manager."

        read -p "Do you want to install Dank Material Shell for niri now? (y/n): " install_dms
        if [[ $install_dms =~ ^[Yy]$ ]]; then
            install_dank_material_shell
        fi
    fi
    
else
    print_error "Failed to build niri. Check the error messages above."
    exit 1
fi

print_status "Installation process completed!"
