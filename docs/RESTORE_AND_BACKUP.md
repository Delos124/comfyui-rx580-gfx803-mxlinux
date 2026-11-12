# Backup and restore

Your important data is stored outside the Docker container in the ComfyUI root directory. Back up that directory before updates or major changes.

## What to back up

At minimum:
- `models/` — model weights (often the largest files).
- `input/` — source images and input assets.
- `output/` — generated images you want to keep.
- `custom_nodes/` — persistent custom extensions.
- `user/` — workflows and ComfyUI user settings.

The Python virtual environment can usually be recreated, but keeping a record of the pinned image digest and dependency list is important.

## Create a backup

Stop ComfyUI first:

```bash
./scripts/stop.sh
```

Then run:

```bash
./scripts/backup.sh /path/to/backup-folder
```

Before running the installer for the first time, you can specify the existing ComfyUI directory explicitly:

```bash
./scripts/backup.sh /path/to/backup-folder /mnt/ai/comfyui
```

Replace both example paths with your actual backup destination and ComfyUI directory.

Replace `/path/to/backup-folder` with a real directory on a different disk. The script creates a timestamped archive. Ensure the destination has enough free space; model folders can be very large.

## Restore

1. Install the same repository version and select the same storage mode.
2. Stop ComfyUI.
3. Extract the archive into a temporary folder and inspect its contents.
4. Copy the saved `models`, `input`, `output`, `custom_nodes`, and user workflow/configuration files into the matching directories.
5. Start ComfyUI and verify the models and workflows.

Do not blindly extract an archive over an existing installation. Inspect it first and preserve the current directory until the restored copy has been tested.

## What this backup does not include

The archive also includes any existing `app/custom_nodes/` and `app/user/` directories from older installs.

The archive does not include Docker's image layers. Re-download the pinned image with:

```bash
sudo docker pull docker.io/woodrex/pytorch-for-gfx803-dev@sha256:2cfc691b39175219352df36d51616ce18ccd387cc9f70a63135808e2d7b00cab
```

Docker's data-root is managed separately from ComfyUI's files.
