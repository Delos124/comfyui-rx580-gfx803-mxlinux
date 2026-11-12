#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
CONTAINER="comfyui-rx580"
echo "=== OS ==="
cat /etc/os-release | grep -E '^(PRETTY_NAME|VERSION_CODENAME)=' || true
uname -r
echo
echo "=== GPU DEVICES ==="
ls -l /dev/kfd /dev/dri 2>&1 || true
echo
echo "=== USER GROUPS ==="
id
echo
echo "=== DOCKER ==="
sudo service docker status 2>&1 || true
sudo docker version 2>&1 || true
DOCKER_ROOT="$(sudo docker info --format '{{.DockerRootDir}}' 2>/dev/null || true)"
echo "Docker data-root: ${DOCKER_ROOT:-unavailable}"
if [[ -n "$DOCKER_ROOT" ]]; then df -h "$DOCKER_ROOT" || true; fi
echo
echo "=== INSTALLATION ==="
if [[ -f "$REPO_DIR/.comfyui-root" ]]; then
  ROOT="$(<"$REPO_DIR/.comfyui-root")"
  echo "ComfyUI root: $ROOT"
  df -h "$ROOT" || true
  git -C "$ROOT/app" rev-parse --short HEAD 2>&1 || true
else
  echo "No local install path recorded. Run install.sh."
fi
echo
echo "=== CONTAINER ==="
sudo docker ps -a --filter "name=^/$CONTAINER$" 2>&1 || true
if sudo docker container inspect "$CONTAINER" >/dev/null 2>&1; then
  STATE="$(sudo docker inspect --format '{{.State.Running}}' "$CONTAINER")"
  if [[ "$STATE" == "true" ]]; then
    sudo docker exec "$CONTAINER" /workspace/comfyui/venv/bin/python -c 'import torch; print("PyTorch:", torch.__version__); print("HIP:", torch.version.hip); print("GPU available:", torch.cuda.is_available()); print("Device:", torch.cuda.get_device_name(0) if torch.cuda.is_available() else "unavailable")' 2>&1 || true
  fi
  echo
  echo "=== LAST CONTAINER LOGS ==="
  sudo docker logs --tail 80 "$CONTAINER" 2>&1 || true
fi
