#!/bin/sh

selection="$(cliphist list | wofi --dmenu --prompt 'Clipboard')"
[ -n "$selection" ] || exit 0
printf '%s\n' "$selection" | cliphist decode | wl-copy
