# Troubleshooting

Run the diagnostic script first:

```bash
./scripts/diagnose.sh
```

## Docker says permission denied

Use the scripts as written; they invoke Docker through `sudo`. If Docker itself is not running:

```bash
sudo service docker status
sudo service docker start
```

The tested MX Linux installation uses SysV service management. Do not assume `systemctl` is available.

## Docker cannot find the GPU devices

Check:

```bash
ls -l /dev/kfd /dev/dri
id
```

The host needs the AMD GPU device nodes and the logged-in user should belong to `video` and `render`. After changing group membership, log out and back in. Do not solve this by running the container with `--privileged`.

## Image download fails or runs out of disk space

The pinned image is about 40 GB. Check Docker storage and free disk space:

```bash
sudo docker info --format '{{.DockerRootDir}}'
df -h
sudo docker system df
```

Do not run `docker system prune -a` as a generic fix. It can delete images and caches used by other projects.

## Browser cannot open ComfyUI

1. Start the container: `./scripts/start.sh`.
2. Check status: `sudo docker ps -a --filter name=comfyui-rx580`.
3. Read logs: `sudo docker logs --tail 200 comfyui-rx580`.
4. Open exactly: http://127.0.0.1:8188

The container publishes the service only on localhost. This is intentional.

## Container exits immediately

Read its logs:

```bash
sudo docker logs --tail 200 comfyui-rx580
```

Check that the selected ComfyUI root contains `app/main.py` and `venv/bin/python`. Do not delete the container or the installation folder before saving the log output.

## PyTorch does not detect the GPU

Run:

```bash
sudo docker exec comfyui-rx580 /workspace/comfyui/venv/bin/python -c "import torch; print(torch.__version__); print(torch.version.hip); print(torch.cuda.is_available()); print(torch.cuda.get_device_name(0) if torch.cuda.is_available() else 'No GPU')"
```

If the container is not running, start it first. Confirm the pinned image digest has not been changed. Do not install a generic PyTorch wheel over the custom gfx803 build.

## Missing optional node or Python package

The tested environment deliberately installs a limited, pinned set of dependencies. Optional nodes may request packages that are not included. Install additional packages only after checking that they support Python 3.10 and do not replace PyTorch, TorchVision, NumPy, or the ROCm runtime.

Never install `torchaudio` from PyPI into this image; the tested package failed to load due to a missing `libtorch_cuda.so`.

## Still stuck?

Run the diagnostic script and share its output, plus the last 100–200 container log lines. Remove usernames, private paths, tokens, and other personal information before posting publicly.
