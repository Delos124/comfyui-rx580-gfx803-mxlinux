#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$HOME/.local/share/applications"
mkdir -p "$APP_DIR"

escape_desktop_path() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value// /\\s}"
  printf '%s' "$value"
}

START_PATH="$(escape_desktop_path "$SCRIPT_DIR/start.sh")"
STOP_PATH="$(escape_desktop_path "$SCRIPT_DIR/stop.sh")"

cat > "$APP_DIR/comfyui-rx580-start.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Start ComfyUI (RX 580)
Comment=Start the local ComfyUI Docker container
Exec=/bin/bash $START_PATH
Icon=utilities-terminal
Terminal=true
Categories=Graphics;
EOF

cat > "$APP_DIR/comfyui-rx580-stop.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Stop ComfyUI (RX 580)
Comment=Stop ComfyUI without deleting models or generated images
Exec=/bin/bash $STOP_PATH
Icon=process-stop
Terminal=true
Categories=Graphics;
EOF

chmod 755 "$APP_DIR/comfyui-rx580-start.desktop" "$APP_DIR/comfyui-rx580-stop.desktop"
printf 'Desktop launchers installed:\n%s\n%s\n' "$APP_DIR/comfyui-rx580-start.desktop" "$APP_DIR/comfyui-rx580-stop.desktop"
printf 'Find them in your application menu: Start ComfyUI (RX 580) and Stop ComfyUI (RX 580).\n'
