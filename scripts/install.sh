#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
IMAGE="docker.io/woodrex/pytorch-for-gfx803-dev@sha256:2cfc691b39175219352df36d51616ce18ccd387cc9f70a63135808e2d7b00cab"
COMFYUI_TAG="v0.2.7"
CONTAINER="comfyui-rx580"

fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
usage() {
  printf 'Usage: %s --mode standard\n' "$0"
  printf '   or: %s --mode partition --mount /mnt/ai\n' "$0"
}
MODE=""
MOUNT="/mnt/ai"
while (($#)); do
  case "$1" in
    --mode) (($# >= 2)) || fail "--mode requires a value"; MODE="$2"; shift 2 ;;
    --mount) (($# >= 2)) || fail "--mount requires a path"; MOUNT="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) usage; fail "Unknown option: $1" ;;
  esac
done

[[ "$MODE" == "standard" || "$MODE" == "partition" ]] || { usage; fail "Choose --mode standard or --mode partition."; }
for cmd in sudo docker git df findmnt; do command -v "$cmd" >/dev/null 2>&1 || fail "Required command missing: $cmd"; done
[[ -e /dev/kfd && -d /dev/dri ]] || fail "GPU device files /dev/kfd and /dev/dri are not present."
sudo service docker status >/dev/null 2>&1 || fail "Docker is not running. Start it with: sudo service docker start"
sudo docker info >/dev/null 2>&1 || fail "Docker is not responding."

if [[ "$MODE" == "standard" ]]; then
  ROOT="$HOME/AI/ComfyUI"
else
  [[ -d "$MOUNT" ]] || fail "Mount directory does not exist: $MOUNT"
  mountpoint -q "$MOUNT" || fail "$MOUNT is not a mounted filesystem. Mount your existing partition first."
  FS_TYPE="$(findmnt -n -o FSTYPE --target "$MOUNT")"
  [[ "$FS_TYPE" == "ext4" ]] || fail "Expected an ext4 partition at $MOUNT; found $FS_TYPE. No files were changed."
  ROOT="$MOUNT/comfyui"
fi

DOCKER_ROOT="$(sudo docker info --format '{{.DockerRootDir}}')"
printf 'ComfyUI data directory: %s\nDocker image storage: %s\n' "$ROOT" "$DOCKER_ROOT"
mkdir -p "$ROOT"
mkdir -p "$ROOT"/{app,models,input,output,custom_nodes}
[[ -w "$ROOT" ]] || fail "You cannot write to $ROOT as the current user."
[[ -w "$ROOT/app" ]] || fail "You cannot write to $ROOT/app."
FREE_KB="$(df -Pk "$DOCKER_ROOT" | awk 'NR==2 {print $4}')"
(( FREE_KB >= 45 * 1024 * 1024 )) || fail "Docker filesystem has less than 45 GiB free. Free space before downloading the image."

if [[ -d "$ROOT/app/.git" ]]; then
  printf 'Existing Git checkout found. Preserving it.\n'
elif [[ -z "$(find "$ROOT/app" -mindepth 1 -maxdepth 1 -print -quit)" ]]; then
  git clone --branch "$COMFYUI_TAG" --depth 1 https://github.com/Comfy-Org/ComfyUI.git "$ROOT/app"
else
  fail "$ROOT/app is non-empty but is not a Git checkout. Move or back it up manually; installer will not overwrite it."
fi

sudo docker pull "$IMAGE"
if [[ -d "$ROOT/venv" ]]; then
  sudo chown -R "$(id -u):$(id -g)" "$ROOT/venv"
fi
if [[ -d "$ROOT/.cache" ]]; then
  sudo chown -R "$(id -u):$(id -g)" "$ROOT/.cache"
fi
sudo docker run --rm \
  --user "$(id -u):$(id -g)" \\
  -e HOME=/workspace/comfyui -e XDG_CACHE_HOME=/workspace/comfyui/.cache \\
  -v "$ROOT:/workspace/comfyui" \
  -v "$REPO_DIR/requirements-gfx803.txt:/tmp/requirements-gfx803.txt:ro" \
  -w /workspace/comfyui/app \
  --entrypoint /bin/bash "$IMAGE" -lc '
    set -e
    if [ ! -x /workspace/comfyui/venv/bin/python ]; then
      python3 -m venv --system-site-packages /workspace/comfyui/venv
    fi
    /workspace/comfyui/venv/bin/python -m pip install -r /tmp/requirements-gfx803.txt
    /workspace/comfyui/venv/bin/python -c "import torch; print(torch.__version__); print(torch.version.hip)"
  '

if sudo docker container inspect "$CONTAINER" >/dev/null 2>&1; then
  EXISTING_ROOT="$(sudo docker inspect --format '{{range .Mounts}}{{if eq .Destination "/workspace/comfyui"}}{{.Source}}{{end}}{{end}}' "$CONTAINER")"
  [[ "$EXISTING_ROOT" == "$ROOT" ]] || fail "Container $CONTAINER already uses $EXISTING_ROOT, not $ROOT. Stop and back up the existing installation before changing storage mode."
  printf 'Container %s already exists and uses the selected data directory; leaving it unchanged.\\n' "$CONTAINER"
else
  sudo docker create --name "$CONTAINER" --restart unless-stopped \
    --user "$(id -u):$(id -g)" \\
    -e HOME=/workspace/comfyui -e XDG_CACHE_HOME=/workspace/comfyui/.cache \\
    --device=/dev/kfd --device=/dev/dri \
    --group-add video --group-add render \
    --security-opt seccomp=unconfined \
    -p 127.0.0.1:8188:8188 \
    -v "$ROOT:/workspace/comfyui" \
    -v "$ROOT/models:/workspace/comfyui/app/models" \
    -v "$ROOT/input:/workspace/comfyui/app/input" \
    -v "$ROOT/output:/workspace/comfyui/app/output" \
    -w /workspace/comfyui/app \
    --entrypoint /bin/bash "$IMAGE" -lc \
    'exec /workspace/comfyui/venv/bin/python main.py --listen 0.0.0.0 --port 8188 --lowvram --use-split-cross-attention' >/dev/null
fi

printf '%s\n' "$ROOT" > "$REPO_DIR/.comfyui-root"
chmod 600 "$REPO_DIR/.comfyui-root"
printf '\nInstallation preparation complete.\n'
printf 'Start ComfyUI with: %s/scripts/start.sh\n' "$REPO_DIR"
printf 'Open: http://127.0.0.1:8188\n'
