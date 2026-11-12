#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
ROOT_FILE="$REPO_DIR/.comfyui-root"
[[ -f "$ROOT_FILE" ]] || { echo "No install path recorded. Run install.sh first." >&2; exit 1; }
[[ $# -eq 1 ]] || { echo "Usage: $0 /path/to/backup-directory" >&2; exit 2; }
ROOT="$(<"$ROOT_FILE")"
DEST="$1"
[[ -d "$ROOT" ]] || { echo "ComfyUI root not found: $ROOT" >&2; exit 1; }
mkdir -p "$DEST"
DEST="$(cd -- "$DEST" && pwd)"
case "$DEST/" in "$ROOT/"*) echo "Backup destination must not be inside the ComfyUI root." >&2; exit 1 ;; esac
STAMP="$(date +%Y%m%d-%H%M%S)"
ARCHIVE="$DEST/comfyui-user-data-$STAMP.tar.gz"
echo "Creating archive: $ARCHIVE"
echo "This includes models, input/output, custom nodes, and user/workflow files; it excludes app source and the Python venv."
tar -czf "$ARCHIVE" -C "$ROOT" --exclude='./app' --exclude='./venv' .
sha256sum "$ARCHIVE" > "$ARCHIVE.sha256"
echo "Backup complete:"
ls -lh "$ARCHIVE" "$ARCHIVE.sha256"
