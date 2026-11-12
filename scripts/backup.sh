#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
ROOT_FILE="$REPO_DIR/.comfyui-root"
[[ $# -ge 1 && $# -le 2 ]] || { echo "Usage: $0 /path/to/backup-directory [comfyui-root]" >&2; exit 2; }
DEST="$1"
if [[ $# -eq 2 ]]; then
  ROOT="$2"
elif [[ -f "$ROOT_FILE" ]]; then
  ROOT="$(<"$ROOT_FILE")"
else
  echo "No install path recorded. Supply the ComfyUI root as the second argument." >&2
  exit 1
fi
[[ -d "$ROOT" ]] || { echo "ComfyUI root not found: $ROOT" >&2; exit 1; }
mkdir -p "$DEST"
DEST="$(cd -- "$DEST" && pwd)"
case "$DEST/" in "$ROOT/"*) echo "Backup destination must not be inside the ComfyUI root." >&2; exit 1 ;; esac
STAMP="$(date +%Y%m%d-%H%M%S)"
ARCHIVE="$DEST/comfyui-user-data-$STAMP.tar.gz"
echo "Creating archive: $ARCHIVE"
echo "This includes models, input/output, custom nodes, and user/workflow files; it excludes app source and the Python venv."
PATHS=()
for RELATIVE_PATH in models input output custom_nodes user app/custom_nodes app/user app/extra_model_paths.yaml; do
  if [[ -e "$ROOT/$RELATIVE_PATH" ]]; then
    PATHS+=("$RELATIVE_PATH")
  fi
done
(( ${#PATHS[@]} > 0 )) || { echo "No recognized user data or model paths found under $ROOT." >&2; exit 1; }
tar -czf "$ARCHIVE" -C "$ROOT" "${PATHS[@]}"
sha256sum "$ARCHIVE" > "$ARCHIVE.sha256"
echo "Backup complete:"
ls -lh "$ARCHIVE" "$ARCHIVE.sha256"
