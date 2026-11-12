#!/usr/bin/env bash
set -Eeuo pipefail
CONTAINER="comfyui-rx580"
if sudo docker container inspect "$CONTAINER" >/dev/null 2>&1; then
  RUNNING="$(sudo docker inspect --format '{{.State.Running}}' "$CONTAINER")"
  if [[ "$RUNNING" == "true" ]]; then
    sudo docker stop --time 30 "$CONTAINER"
    echo "ComfyUI stopped. Your models and output files were preserved."
  else
    echo "ComfyUI is already stopped."
  fi
else
  echo "ComfyUI container does not exist. Run scripts/install.sh first."
fi
