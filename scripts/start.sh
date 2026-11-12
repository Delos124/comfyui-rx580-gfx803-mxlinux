#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
ROOT_FILE="$REPO_DIR/.comfyui-root"
CONTAINER="comfyui-rx580"
[[ -f "$ROOT_FILE" ]] || { echo "Run scripts/install.sh first." >&2; exit 1; }
ROOT="$(<"$ROOT_FILE")"
[[ -d "$ROOT/app" && -x "$ROOT/venv-gfx803/bin/python" ]] || { echo "ComfyUI app or Python 3.10 gfx803 environment is missing under $ROOT." >&2; exit 1; }
sudo docker container inspect "$CONTAINER" >/dev/null 2>&1 || { echo "Container not found. Run scripts/install.sh." >&2; exit 1; }
sudo docker start "$CONTAINER"
printf '\nComfyUI is starting. Open http://127.0.0.1:8188\n'
printf 'Logs: sudo docker logs -f %s\n' "$CONTAINER"
