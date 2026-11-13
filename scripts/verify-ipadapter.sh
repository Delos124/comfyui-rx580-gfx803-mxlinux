#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
API_URL="${COMFYUI_API_URL:-http://127.0.0.1:8188/object_info}"
EXTENSION_NAME="ComfyUI_IPAdapter_plus_old"
EXTENSION_REMOTE="https://github.com/meimeilook/ComfyUI_IPAdapter_plus.old"
EXTENSION_REVISION="ebd80fd896e738085ae139a4f31c76f4c3f1af08"

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

[[ -f "$REPO_DIR/.comfyui-root" ]] || fail "No .comfyui-root found. Run scripts/install.sh first."
ROOT="$(<"$REPO_DIR/.comfyui-root")"
[[ -d "$ROOT" ]] || fail "ComfyUI root does not exist: $ROOT"

printf 'ComfyUI root: %s\n' "$ROOT"

printf '\n=== PINNED IP-ADAPTER EXTENSION ===\n'
EXTENSION="$ROOT/custom_nodes/$EXTENSION_NAME"
[[ -d "$EXTENSION/.git" ]] || fail "Extension Git checkout is missing: $EXTENSION. Run scripts/install-ipadapter.sh."
command -v git >/dev/null 2>&1 || fail "git is required to verify the extension."
ACTUAL_REMOTE="$(git -C "$EXTENSION" remote get-url origin 2>/dev/null)" || fail "Extension has no origin remote."
ACTUAL_REMOTE="${ACTUAL_REMOTE%.git}"
[[ "$ACTUAL_REMOTE" == "$EXTENSION_REMOTE" ]] || fail "Unexpected extension origin: $ACTUAL_REMOTE"
ACTUAL_REVISION="$(git -C "$EXTENSION" rev-parse HEAD)"
[[ "$ACTUAL_REVISION" == "$EXTENSION_REVISION" ]] || fail "Expected extension revision $EXTENSION_REVISION, found $ACTUAL_REVISION"
printf 'PASS: %s @ %s\n' "$EXTENSION_NAME" "$ACTUAL_REVISION"

printf '\n=== IP-ADAPTER MODEL ===\n'
MODEL="$ROOT/models/ipadapter/ip-adapter_sd15.safetensors"
[[ -s "$MODEL" ]] || fail "Missing or empty model: $MODEL"
ls -lh "$MODEL"

printf '\n=== CLIP VISION ENCODER ===\n'
ENCODER="$ROOT/models/clip_vision/CLIP-ViT-H-14-laion2B-s32B-b79K.safetensors"
[[ -s "$ENCODER" ]] || fail "Missing or empty ViT-H encoder: $ENCODER. The SD 1.5 base IP-Adapter workflow requires this separate encoder."
ls -lh "$ENCODER"

printf '\n=== COMFYUI NODE REGISTRATION ===\n'
command -v python3 >/dev/null 2>&1 || fail "python3 is required for the API check."

python3 - "$API_URL" <<'PY'
import json
import sys
import urllib.error
import urllib.request

url = sys.argv[1]
try:
    with urllib.request.urlopen(url, timeout=8) as response:
        data = json.load(response)
except (OSError, urllib.error.URLError, json.JSONDecodeError) as exc:
    print(f"FAIL: Cannot query {url}: {exc}", file=sys.stderr)
    raise SystemExit(1)

expected = (
    "old_IPAdapterModelLoader",
    "old_IPAdapterApply",
    "CLIPVisionLoader",
    "CLIPVisionEncode",
)
registered = sorted(name for name in data if "ipadapter" in name.lower() or name in expected)
for name in registered:
    print(name)

missing = [name for name in expected if name not in data]
if missing:
    print("FAIL: Missing required nodes: " + ", ".join(missing), file=sys.stderr)
    raise SystemExit(1)

print("PASS: IP-Adapter and CLIP Vision nodes are registered.")
PY

printf '\nPASS: Pinned extension, both model files, and required nodes verified.\n'
printf 'A successful verification does not replace a completed image-generation workflow test.\n'
