# Installation guide

This guide is written for first-time Linux users. Read it once before running commands. Do not skip the safety checks.

## 1. What this installs

ComfyUI runs inside Docker using a community-built PyTorch/ROCm image adapted for the older AMD RX 580 (gfx803). Docker keeps this legacy GPU software separate from MX Linux.

This is not an official AMD-supported ROCm configuration. The tested image is large (about 40 GB). Model files need additional space.

## 2. Requirements

- MX Linux with a working graphical desktop.
- AMD Radeon RX 580 4 GB (gfx803).
- Docker Engine installed and running.
- Internet access for the first image download and ComfyUI source checkout.
- At least 45 GB free in Docker's configured data-root, plus space for models and outputs.
- Your Linux account should have access to the GPU device groups `video` and `render`.

Check Docker:

```bash
sudo service docker status
sudo docker version
```

If Docker is not installed, stop here and install Docker Engine using the official Docker instructions for Debian-compatible distributions. MX Linux uses SysV service commands in the tested setup; do not follow systemd-only commands blindly.

Check the GPU devices:

```bash
ls -l /dev/kfd /dev/dri
id
```

The tested host exposes `/dev/kfd`, `/dev/dri/card0`, and `/dev/dri/renderD128`. Your user should be a member of `video` and `render`. If a group is missing, add it with `sudo usermod -aG video,render "$USER"`, then log out of MX Linux completely and log back in.

## 3. Choose where ComfyUI files live

The installer supports two layouts. Neither option formats disks or moves Docker's image storage.

### Option A — normal folder (recommended for most people)

ComfyUI files live in your home directory:

```text
~/AI/ComfyUI/
  app/          ComfyUI source code
  venv-gfx803/  Python 3.10 environment used by the RX 580 container
  models/       Checkpoints, LoRAs, VAE files, etc.
  input/        Images supplied to workflows
  output/       Generated images
  custom_nodes/ Persistent custom nodes
  user/         Workflows and ComfyUI user settings
```

Docker stores downloaded container images wherever Docker is configured to store them (commonly `/var/lib/docker`). Make sure that filesystem has enough free space.

### Option B — an already-mounted dedicated partition

Use this only if you already have a separate Linux ext4 partition mounted at a path such as `/mnt/ai`. The installer checks that the path is a mounted ext4 filesystem before writing.

Example layout:

```text
/mnt/ai/
  docker/       Docker data-root, only if you configured it separately
  comfyui/
    app/
    venv/
    models/
    input/
    output/
    custom_nodes/
    user/
```

The installer does not configure Docker's data-root. If you want Docker images on the partition, configure that separately using Docker's official storage documentation. Do not copy, delete, or migrate an existing Docker data-root as part of this installation.

## 4. Download the repository

Open a terminal. Copy and paste these commands:

```bash
mkdir -p "$HOME/AI"
cd "$HOME/AI"
git clone https://github.com/Delos124/comfyui-rx580-gfx803-mxlinux.git
cd comfyui-rx580-gfx803-mxlinux
```

If Git is missing, install it with your MX Linux package manager, then repeat the commands.

## 5. Install

For Option A:

```bash
chmod +x scripts/*.sh
./scripts/install.sh --mode standard
```

For Option B, replace `/mnt/ai` with the actual mount point of your ext4 partition:

```bash
chmod +x scripts/*.sh
./scripts/install.sh --mode partition --mount /mnt/ai
```

The installer will:
1. Check required commands, Docker, GPU device files, and available disk space.
2. Create the ComfyUI folder structure without deleting existing files.
3. Download the pinned ComfyUI source tag if the app folder is empty.
4. Download the pinned Docker image by digest.
5. Create a separate Python 3.10 virtual environment (`venv-gfx803`) inside the pinned container image and install the repository's pinned dependencies. Any older host-side `venv/` is left untouched.
6. Create a stopped Docker container named `comfyui-rx580`.

It will not format partitions, change host graphics drivers, install ROCm on the host, or move Docker storage. If it finds an existing non-empty app folder, it will preserve it and stop rather than overwrite it.

## 6. Start ComfyUI

```bash
./scripts/start.sh
```

Wait for the startup message, then open this address in your browser:

http://127.0.0.1:8188

Keep the terminal open if you want to watch the live log. To see the last 100 log lines in another terminal:

```bash
sudo docker logs --tail 100 comfyui-rx580
```

## 7. Stop ComfyUI

```bash
./scripts/stop.sh
```

This stops the container without deleting your models, settings, or output images. Do not use `docker rm` unless you intentionally want to remove the container.

## 8. Verify GPU support

Run:

```bash
./scripts/diagnose.sh
```

Inside the container, PyTorch should report that CUDA-compatible device APIs are available and identify the Radeon RX 580. ROCm builds of PyTorch use the `torch.cuda` API name for compatibility; this does not mean an NVIDIA GPU is installed.

Expected ComfyUI startup characteristics on the tested RX 580:
- Approximately 4096 MB total VRAM.
- Radeon RX 580 Series as the active device.
- Low-VRAM mode.
- Split cross-attention enabled.

## 9. Add model files

Place model files in the appropriate subfolders under the selected ComfyUI root, for example:

- Checkpoints: `models/checkpoints/`
- LoRAs: `models/loras/`
- VAE: `models/vae/`
- ControlNet: `models/controlnet/`
- Upscalers: `models/upscale_models/`

Never upload model weights to this GitHub repository. Check each model's license and source before downloading or sharing it.

## 10. Update ComfyUI

The source version and GPU image are pinned intentionally. Do not run `git pull` or update PyTorch/ROCm packages casually: newer versions can break this legacy gfx803 stack.

Use `scripts/update.sh` only after reading its confirmation prompt and backing up your installation. The script updates ComfyUI source only; it does not change the container image or Python package versions.
