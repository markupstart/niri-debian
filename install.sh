#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

sudo cp "$SCRIPT_DIR/sources.list" /etc/apt/sources.list
sudo dpkg --add-architecture i386
sudo DEBIAN_FRONTEND=noninteractive APT_LISTCHANGES_FRONTEND=none \
	apt-get update

# Add the official VS Code repository for Debian installs.
sudo DEBIAN_FRONTEND=noninteractive APT_LISTCHANGES_FRONTEND=none \
	apt-get install -y wget gpg apt-transport-https
sudo DEBIAN_FRONTEND=noninteractive APT_LISTCHANGES_FRONTEND=none \
	apt-get update

grep -vx 'gdm3' "$SCRIPT_DIR/packages.txt" | xargs \
	sudo DEBIAN_FRONTEND=noninteractive APT_LISTCHANGES_FRONTEND=none \
	apt-get install -y \
	-o Dpkg::Options::=--force-confdef \
	-o Dpkg::Options::=--force-confold

if grep -qx 'gdm3' "$SCRIPT_DIR/packages.txt"; then
	sudo DEBIAN_FRONTEND=noninteractive APT_LISTCHANGES_FRONTEND=none \
		apt-get install -y --no-install-recommends \
		-o Dpkg::Options::=--force-confdef \
		-o Dpkg::Options::=--force-confold \
		gdm3
fi

sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
sudo flatpak install -y --noninteractive flathub \
	com.dec05eba.gpu_screen_recorder \
	com.discordapp.Discord \
	com.obsproject.Studio \
	com.obsproject.Studio.Plugin.GStreamerVaapi \
	com.obsproject.Studio.Plugin.Gstreamer \
	com.obsproject.Studio.Plugin.OBSVkCapture \
	fr.handbrake.ghb \
	io.missioncenter.MissionCenter \
	org.audacityteam.Audacity \
	org.gimp.GIMP \
	org.gimp.GIMP.Plugin.Resynthesizer \
	org.gnome.Boxes \
	org.gnome.Showtime \
	org.inkscape.Inkscape \
	org.kde.kdenlive

mkdir -p "$HOME/.config"

for config_dir in niri yazi mpd rmpc; do
	CONFIG_SOURCE="$SCRIPT_DIR/config/$config_dir"
	CONFIG_DEST="$HOME/.config/$config_dir"

	if [ -d "$CONFIG_SOURCE" ]; then
		mkdir -p "$CONFIG_DEST"
		cp -a "$CONFIG_SOURCE"/. "$CONFIG_DEST"/
	fi
done

bash "$SCRIPT_DIR/install_niri.sh"
