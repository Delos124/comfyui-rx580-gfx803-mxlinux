# Configuration reference

## Pinned components

- ComfyUI source tag: `v0.2.7`
- ComfyUI commit: `696672905fd17af2654ced11e3ab590d6a555996`
- Container image: `docker.io/woodrex/pytorch-for-gfx803-dev`
- Container image digest: `sha256:2cfc691b39175219352df36d51616ce18ccd387cc9f70a63135808e2d7b00cab`
- Runtime flags: `--lowvram --use-split-cross-attention`
- Host binding: `127.0.0.1:8188`

## Container GPU access

The container receives only the required GPU devices and groups:
- `/dev/kfd`
- `/dev/dri`
- `video` and `render` supplementary groups
- `seccomp=unconfined`, required by the tested container setup

It does not use Docker's `--privileged` mode.

## Dependency pins

See `requirements-gfx803.txt` in the repository. The venv is created with `--system-site-packages` so it can access the custom PyTorch and TorchVision packages baked into the pinned container image.

Do not install upstream ComfyUI requirements wholesale into this environment. That can replace or conflict with the custom GPU-enabled PyTorch stack.
