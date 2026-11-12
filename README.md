# ComfyUI on AMD RX 580 (gfx803) — MX Linux

Beginner-friendly documentation for a Docker-isolated ComfyUI setup targeting the AMD Radeon RX 580 4 GB (gfx803) on MX Linux.

## Start here

Read [Installation](docs/INSTALLATION.md) before running any commands. The guide covers prerequisites, both storage layouts, installation, startup, shutdown, and verification.

## Recorded working configuration

- AMD Radeon RX 580, 4 GB VRAM (gfx803)
- MX Linux, Debian 13/Trixie base
- Docker Engine
- Container image: `woodrex/pytorch-for-gfx803-dev`
- Image digest: `sha256:2cfc691b39175219352df36d51616ce18ccd387cc9f70a63135808e2d7b00cab`
- ROCm 5.5.1 inside the container
- Custom PyTorch 2.1.2 gfx803 build
- ComfyUI v0.2.7

This is a community compatibility workaround, not an official AMD-supported ROCm configuration. Results may vary on other hardware and software versions.

## Installation locations

- Standard: `~/AI/ComfyUI`
- Existing ext4 partition: `/mnt/ai/comfyui` (requires the partition to be mounted already)

The installer must never format a disk, create partitions, change host graphics drivers, install host ROCm, or migrate Docker's data directory. Docker image storage remains in Docker's configured data-root.

## Guides

- [Installation](docs/INSTALLATION.md)
- [Hardware compatibility](docs/HARDWARE_COMPATIBILITY.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)
- [Backup and restore](docs/RESTORE_AND_BACKUP.md)

## Security and storage

The image is approximately 40 GB in the recorded setup; allow at least 45 GB of free space for it and working files. Model weights require additional storage. Bind the ComfyUI web interface to `127.0.0.1` unless you deliberately configure and secure remote access.

Do not commit model weights, credentials, access tokens, private keys, or personal machine configuration. No repository license has been selected; do not assume reuse or redistribution rights without one.
