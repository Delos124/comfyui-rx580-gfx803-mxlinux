# ComfyUI on AMD RX 580 (gfx803) — MX Linux

Beginner-friendly documentation and setup scripts for a Docker-isolated ComfyUI installation targeting the AMD Radeon RX 580 4 GB (gfx803) on MX Linux.

## Start here

1. Read [Installation](docs/INSTALLATION.md).
2. Choose standard storage (`~/AI/ComfyUI`) or an already-mounted ext4 partition (for example, `/mnt/ai/comfyui`).
3. Run the installer, then start ComfyUI using the scripts.

## Recorded working configuration

- AMD Radeon RX 580, 4 GB VRAM (gfx803)
- MX Linux, Debian 13/Trixie base
- Docker Engine 29.9.3
- Container image: `woodrex/pytorch-for-gfx803-dev`
- Image digest: `sha256:2cfc691b39175219352df36d51616ce18ccd387cc9f70a63135808e2d7b00cab`
- ROCm 5.5.1 inside the container
- Custom PyTorch 2.1.2 gfx803 build
- TorchVision 0.16.2
- ComfyUI v0.2.7

This is a community compatibility workaround, not an official AMD-supported ROCm configuration. Results may vary on other hardware and software versions.

## Guides

- [Installation](docs/INSTALLATION.md)
- [Quick start](docs/QUICK_START.md)
- [Configuration](docs/CONFIGURATION.md)
- [Hardware compatibility](docs/HARDWARE_COMPATIBILITY.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)
- [Backup and restore](docs/RESTORE_AND_BACKUP.md)
- [Repository map](docs/README_STRUCTURE.md)
- [Security policy](SECURITY.md)

## Main scripts

```bash
# Make the scripts executable once after cloning
chmod +x scripts/*.sh

# Standard installation
./scripts/install.sh --mode standard

# Use an existing, mounted ext4 partition
./scripts/install.sh --mode partition --mount /mnt/ai

# Start / stop / diagnose
./scripts/start.sh
./scripts/stop.sh
./scripts/diagnose.sh
```

The installer never formats disks, creates partitions, changes host graphics drivers, installs host ROCm, or migrates Docker's data directory. Docker image storage remains in Docker's configured data-root.

## Storage and security

The image is approximately 40 GB in the recorded setup; allow at least 45 GB free on Docker's data filesystem, plus space for models and outputs. The web interface binds to `127.0.0.1:8188` and is not exposed to your local network by default.

Do not commit model weights, credentials, access tokens, private keys, or personal machine configuration. No repository license has been selected; do not assume reuse or redistribution rights without one.
