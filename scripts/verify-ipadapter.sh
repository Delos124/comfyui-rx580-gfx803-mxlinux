#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
CONTAINER="comfyui-rx580"
API_URL="http://127.0.0.1:8188/object_info"

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
warn() { printf 'WARN: %s\n' "$*" >&2; }

[[ -f "$REPO_DIR/.comfyui-root" ]] || fail "No .comfyui-root found. Run scripts/install.sh first."
ROOT="$(<"$REPO_DIR/.comfyui-root")"
[[ -d "$ROOT" ]] || fail "ComfyUI root does not exist: $ROOT"

printf 'ComfyUI root: %s\n' "$ROOT"
printf '\n=== IP-ADAPTER MODEL ===\n'
MODEL="$ROOT/models/ipadapter/ip-adapter_sd15.safetensors"
if [[ -s "$MODEL" ]]; then
  ls -lh "$MODEL"
else
  fail "Missing or empty model: $MODEL"
fi

printf '\n=== CLIP VISION ENCODER ===\n'
ENCODER="$ROOT/models/clip_vision/CLIP-ViT-H-14-laion2B-s32B-b79K.safetensors"
if [[ -s "$ENCODER" ]]; then
  ls -lh "$ENCODER"
else
  warn "Missing ViT-H encoder: $ENCODER"
  printf 'The SD 1.5 base IP-Adapter workflow requires this separate encoder.\n'
fi

printf '\n=== COMFYUI NODE REGISTRATION ===\n'
if ! command -v python3 >/dev/null 2>&1; then
  fail "python3 is required for the API check."
fi

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
)
registered = sorted(name for name in data if "ipadapter" in name.lower())
for name in registered:
    print(name)

missing = [name for name in expected if name not in data]
if missing:
    print("FAIL: Missing required nodes: " + ", ".join(missing), file=sys.stderr)
    raise SystemExit(1)

print("PASS: Legacy IP-Adapter model loader and apply nodes are registered.")
PY

printf '\nRegistration and model-file checks passed. A completed generation test is still required to validate the full workflow.\n'
