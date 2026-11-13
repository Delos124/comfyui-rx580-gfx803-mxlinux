#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
EXTENSION_NAME="ComfyUI_IPAdapter_plus_old"
EXTENSION_REMOTE="https://github.com/meimeilook/ComfyUI_IPAdapter_plus.old.git"
EXTENSION_REVISION="ebd80fd896e738085ae139a4f31c76f4c3f1af08"

fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

[[ -f "$REPO_DIR/.comfyui-root" ]] || fail "No .comfyui-root found. Run scripts/install.sh first."
ROOT="$(<"$REPO_DIR/.comfyui-root")"
[[ -d "$ROOT/custom_nodes" ]] || fail "Missing custom_nodes directory: $ROOT/custom_nodes"
command -v git >/dev/null 2>&1 || fail "git is required."

TARGET="$ROOT/custom_nodes/$EXTENSION_NAME"

if [[ -e "$TARGET" ]]; then
  [[ -d "$TARGET/.git" ]] || fail "Target exists but is not a Git checkout. Nothing was changed: $TARGET"
  ACTUAL_REMOTE="$(git -C "$TARGET" remote get-url origin 2>/dev/null)" || fail "Existing extension has no origin remote. Nothing was changed."
  [[ "${ACTUAL_REMOTE%.git}" == "${EXTENSION_REMOTE%.git}" ]] || fail "Existing extension has a different origin: $ACTUAL_REMOTE. Nothing was changed."
  ACTUAL_REVISION="$(git -C "$TARGET" rev-parse HEAD)"
  [[ "$ACTUAL_REVISION" == "$EXTENSION_REVISION" ]] || fail "Existing extension is at $ACTUAL_REVISION, expected $EXTENSION_REVISION. Nothing was changed."
  printf 'Already installed at the required revision: %s\n' "$ACTUAL_REVISION"
  exit 0
fi

TEMP_DIR="$(mktemp -d "$ROOT/custom_nodes/.ipadapter-install.XXXXXX")"
cleanup() { rm -rf -- "$TEMP_DIR"; }
trap cleanup EXIT

git clone --no-checkout "$EXTENSION_REMOTE" "$TEMP_DIR/$EXTENSION_NAME"
git -C "$TEMP_DIR/$EXTENSION_NAME" checkout --detach "$EXTENSION_REVISION"
ACTUAL_REVISION="$(git -C "$TEMP_DIR/$EXTENSION_NAME" rev-parse HEAD)"
[[ "$ACTUAL_REVISION" == "$EXTENSION_REVISION" ]] || fail "Cloned revision mismatch: $ACTUAL_REVISION"

mv -- "$TEMP_DIR/$EXTENSION_NAME" "$TARGET"
printf 'Installed %s at %s\n' "$EXTENSION_NAME" "$ACTUAL_REVISION"
printf 'Restart ComfyUI, then run: bash "%s/scripts/verify-ipadapter.sh"\n' "$REPO_DIR"
