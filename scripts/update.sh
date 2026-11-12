#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
ROOT_FILE="$REPO_DIR/.comfyui-root"
[[ -f "$ROOT_FILE" ]] || { echo "Run install.sh first." >&2; exit 1; }
ROOT="$(<"$ROOT_FILE")"
APP="$ROOT/app"
[[ -d "$APP/.git" ]] || { echo "ComfyUI source is not a Git checkout: $APP" >&2; exit 1; }
echo "This changes ComfyUI source only. It does not update ROCm, PyTorch, the container image, or Python dependencies."
echo "Back up your workflows and user data before proceeding."
CURRENT="$(git -C "$APP" rev-parse --short HEAD)"
echo "Current source commit: $CURRENT"
read -r -p "Enter the exact ComfyUI tag to check out (example: v0.2.7), or press Enter to cancel: " TAG
[[ -n "$TAG" ]] || { echo "Cancelled."; exit 0; }
[[ "$TAG" =~ ^v[0-9]+\.[0-9]+\.[0-9]+([.-][A-Za-z0-9.-]+)?$ ]] || { echo "Tag format rejected. Use a version tag such as v0.2.7." >&2; exit 2; }
read -r -p "Type UPDATE to fetch and switch to $TAG: " CONFIRM
[[ "$CONFIRM" == "UPDATE" ]] || { echo "Cancelled."; exit 0; }
git -C "$APP" fetch --tags --force
git -C "$APP" rev-parse --verify "refs/tags/$TAG" >/dev/null || { echo "Tag not found: $TAG" >&2; exit 1; }
git -C "$APP" checkout --detach "$TAG"
echo "Updated source to $TAG ($(git -C "$APP" rev-parse --short HEAD))."
echo "If startup fails, return to the previous commit with: git -C '$APP' checkout --detach $CURRENT"
