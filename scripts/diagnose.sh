#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
CONTAINER="${COMFYUI_CONTAINER:-comfyui-rx580}"
API_URL="${COMFYUI_API_URL:-http://127.0.0.1:8188}"
ROOT_FILE="$REPO_DIR/.comfyui-root"
ROOT=""

section() { printf '\n===== %s =====\n' "$1"; }
run() { printf '\n$'; printf ' %q' "$@"; printf '\n'; "$@" 2>&1 || true; }

section "HOST"
if [[ -r /etc/os-release ]]; then
  . /etc/os-release
  printf 'OS: %s (%s)\n' "${PRETTY_NAME:-unknown}" "${VERSION_CODENAME:-unknown}"
fi
printf 'Kernel: %s | Architecture: %s\n' "$(uname -r)" "$(uname -m)"
printf 'CPU: %s\n' "$(lscpu 2>/dev/null | awk -F: '/Model name/ {sub(/^[ \t]+/, "", $2); print $2; exit}')"
printf 'Logical CPUs: %s\n' "$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo unknown)"
run free -h
run id

section "GPU AND DEVICE ACCESS"
run lspci -nnk
run ls -l /dev/kfd /dev/dri
printf 'GPU access groups: '
id -nG | tr ' ' '\n' | grep -E '^(video|render)$' | paste -sd, - || true

section "STORAGE"
run df -hT /
if [[ -f "$ROOT_FILE" ]]; then
  ROOT="$(<"$ROOT_FILE")"
  printf 'ComfyUI root: %s\n' "$ROOT"
  [[ -d "$ROOT" ]] && run df -hT "$ROOT"
  for path in models custom_nodes output user input; do
    [[ -d "$ROOT/$path" ]] && run du -sh "$ROOT/$path"
  done
else
  printf 'No .comfyui-root file found.\n'
fi

section "DOCKER"
DOCKER=()
if command -v docker >/dev/null 2>&1; then
  DOCKER=(docker)
  if ! docker info >/dev/null 2>&1; then DOCKER=(sudo docker); fi
  run "${DOCKER[@]}" version
  run "${DOCKER[@]}" info --format 'Docker root: {{.DockerRootDir}} | Storage: {{.Driver}}'
  run "${DOCKER[@]}" ps -a --filter "name=^/$CONTAINER$" --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}\t{{.Ports}}'
else
  printf 'Docker CLI not found.\n'
fi

section "CONTAINER CONFIGURATION AND RUNTIME"
if [[ "${#DOCKER[@]}" -gt 0 ]] && "${DOCKER[@]}" container inspect "$CONTAINER" >/dev/null 2>&1; then
  "${DOCKER[@]}" inspect --format 'Name: {{.Name}}
State: {{.State.Status}}
Image: {{.Config.Image}}
Image ID: {{.Image}}
Restart policy: {{.HostConfig.RestartPolicy.Name}}
Network: {{.HostConfig.NetworkMode}}
Ports: {{json .HostConfig.PortBindings}}
Mounts: {{range .Mounts}}{{println .Source "->" .Destination}}{{end}}' "$CONTAINER" 2>&1 || true

  if [[ "$("${DOCKER[@]}" inspect --format '{{.State.Running}}' "$CONTAINER" 2>/dev/null || true)" == "true" ]]; then
    "${DOCKER[@]}" exec "$CONTAINER" /workspace/comfyui/venv-gfx803/bin/python - <<'PY' 2>&1 || true
import importlib.util
import platform
import sys

print("Python:", sys.version.replace("\\n", " "))
print("Executable:", sys.executable)
print("Platform:", platform.platform())
try:
    import torch
    print("PyTorch:", torch.__version__)
    print("Torch CUDA build:", torch.version.cuda)
    print("HIP:", torch.version.hip)
    print("GPU available:", torch.cuda.is_available())
    print("GPU count:", torch.cuda.device_count())
    if torch.cuda.is_available():
        props = torch.cuda.get_device_properties(0)
        print("GPU:", torch.cuda.get_device_name(0))
        print("VRAM:", round(props.total_memory / 1024**3, 2), "GiB")
except Exception as exc:
    print("Torch probe failed:", repr(exc))
for package in ("torchvision", "torchaudio", "transformers", "safetensors"):
    print(f"{package} installed:", importlib.util.find_spec(package) is not None)
PY

    section "COMFYUI SOURCE AND EXTENSIONS"
    "${DOCKER[@]}" exec "$CONTAINER" bash -lc '
      cd /workspace/comfyui/app
      printf "ComfyUI commit: "; git rev-parse --short HEAD 2>/dev/null || echo unavailable
      printf "ComfyUI tag: "; git describe --tags --exact-match 2>/dev/null || echo untagged
      printf "Custom nodes:\n"
      find custom_nodes -mindepth 1 -maxdepth 1 -type d -printf "%f\n" 2>/dev/null | sort
    ' 2>&1 || true
  else
    printf 'Container is stopped; runtime probes skipped.\n'
  fi
else
  printf 'Container %s not found or Docker unavailable.\n' "$CONTAINER"
fi

section "COMFYUI API"
if command -v python3 >/dev/null 2>&1; then
  python3 - "$API_URL" <<'PY' 2>&1 || true
import json
import sys
import urllib.request

base = sys.argv[1].rstrip("/")
for endpoint in ("/system_stats", "/object_info"):
    try:
        with urllib.request.urlopen(base + endpoint, timeout=5) as response:
            data = json.load(response)
        print(endpoint + ": HTTP OK")
        if endpoint == "/system_stats":
            system = data.get("system", {})
            print("  ComfyUI:", system.get("comfyui_version", "unknown"))
            print("  Python:", system.get("python_version", "unknown"))
            for device in data.get("devices", []):
                print("  Device:", device.get("name", "unknown"))
                print("  VRAM total/free:", device.get("vram_total", "?"), "/", device.get("vram_free", "?"))
        else:
            names = sorted(data)
            print("  Registered nodes:", len(names))
            for term in ("ipadapter", "clipvision", "controlnet", "lora", "checkpoint", "vae", "ksampler"):
                matches = [name for name in names if term in name.lower()]
                print(f"  {term}: {len(matches)}")
                for name in matches[:10]:
                    print("   -", name)
    except Exception as exc:
        print(f"{endpoint}: unavailable ({exc})")
PY
else
  printf 'Host Python 3 unavailable; API probe skipped.\n'
fi

section "MODEL INVENTORY"
if [[ -n "$ROOT" && -d "$ROOT/models" ]]; then
  for category in checkpoints clip_vision ipadapter loras controlnet vae upscale_models; do
    dir="$ROOT/models/$category"
    if [[ -d "$dir" ]]; then
      printf '\n%s:\n' "$category"
      find "$dir" -maxdepth 1 -type f -printf '%f (%s bytes)\n' | sort | head -n 25
    fi
  done
fi

section "GIT STATE"
if git -C "$REPO_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  printf 'Infrastructure repository: %s\n' "$REPO_DIR"
  run git -C "$REPO_DIR" status --short --branch
  run git -C "$REPO_DIR" log -1 --format='%h %s'
fi
if [[ -n "$ROOT" && -d "$ROOT/app/.git" ]]; then
  printf '\nComfyUI application repository:\n'
  run git -C "$ROOT/app" status --short --branch
  run git -C "$ROOT/app" log -1 --format='%h %s'
fi

section "RECENT CONTAINER LOGS"
if [[ "${#DOCKER[@]}" -gt 0 ]] && "${DOCKER[@]}" container inspect "$CONTAINER" >/dev/null 2>&1; then
  "${DOCKER[@]}" logs --tail 35 "$CONTAINER" 2>&1 || true
fi

printf '\n===== DIAGNOSTIC COMPLETE =====\n'
printf 'Read-only: no installation, update, deletion, or file modification performed.\n'
