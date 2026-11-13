# Repository map

- `scripts/install.sh` — safe first-time setup for standard or already-mounted ext4 storage.
- `scripts/start.sh` — starts the persistent Docker container.
- `scripts/stop.sh` — gracefully stops the container without deleting data.
- `scripts/diagnose.sh` — collects hardware, Docker, Python GPU, and log diagnostics.
- `scripts/verify-ipadapter.sh` — checks the local IP-Adapter API nodes and required SD 1.5 model files.
- `scripts/backup.sh` — archives user data and writes a SHA-256 checksum.
- `scripts/update.sh` — interactively checks out an explicitly selected ComfyUI tag.
- `requirements-gfx803.txt` — pinned Python packages validated with the recorded custom PyTorch image.
- `docs/` — beginner installation, configuration, compatibility, IP-Adapter, troubleshooting, backup, and quick-start guides.

The installer writes a local `.comfyui-root` file beside the scripts. This file is ignored by Git because it contains a machine-specific absolute path.
