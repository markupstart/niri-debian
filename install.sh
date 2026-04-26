#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

sudo cp "$SCRIPT_DIR/sources.list" /etc/apt/sources.list
sudo dpkg --add-architecture i386
sudo DEBIAN_FRONTEND=noninteractive APT_LISTCHANGES_FRONTEND=none \
	apt-get update

xargs -a "$SCRIPT_DIR/packages.txt" \
	sudo DEBIAN_FRONTEND=noninteractive APT_LISTCHANGES_FRONTEND=none \
	apt-get install -y \
	-o Dpkg::Options::=--force-confdef \
	-o Dpkg::Options::=--force-confold
bash "$SCRIPT_DIR/install_niri.sh"
