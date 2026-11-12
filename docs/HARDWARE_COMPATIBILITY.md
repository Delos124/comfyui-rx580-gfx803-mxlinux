# Hardware compatibility and tested stack

## Tested machine

| Component | Tested value |
|---|---|
| GPU | AMD Radeon RX 580, 4 GB |
| GPU architecture target | gfx803 / Polaris |
| CPU | AMD Ryzen 5 1600 |
| System memory | 8 GB RAM |
| OS | MX Linux, Debian 13/Trixie base |
| Kernel | 7.3.4-1-liquorix-amd64 |
| Mesa | 26.1.4 |
| Docker Engine | 29.9.3 |
| Docker Compose | 5.7.1 |
| ComfyUI | v0.2.7, commit 696672905fd17af2654ced11e3ab590d6a555996 |

The exact host kernel and Mesa versions are observations from one installation, not requirements for every user.

## Container image

Pinned image:

```text
docker.io/woodrex/pytorch-for-gfx803-dev@sha256:2cfc691b39175219352df36d51616ce18ccd387cc9f70a63135808e2d7b00cab
```

Recorded container stack:
- Ubuntu 22.04
- Python 3.10.12
- ROCm 5.5.1
- Custom PyTorch 2.1.2 gfx803 build
- TorchVision 0.16.2
- HIP runtime reports 5.5.30202-eaf00c0b

The image publisher and image digest are external dependencies. Review the publisher's source and trust model before using it. This repository does not build or audit that image.

## Validated GPU checks

The following were successfully run on the recorded machine:
- HIP vector addition (4096 values).
- PyTorch matrix multiplication (512 × 512).
- PyTorch Conv2d operation.
- `torch.cuda.is_available()` returned true inside the ROCm build.
- ComfyUI detected Radeon RX 580 Series and reported 4096 MB VRAM.

## Why the container uses `torch.cuda`

ROCm-enabled PyTorch maintains compatibility with the PyTorch `torch.cuda` namespace. Seeing `cuda:0` in ComfyUI logs does not imply NVIDIA CUDA drivers or an NVIDIA GPU.

## Known limitations

- 4 GB VRAM is restrictive. Start with small SD 1.5 workflows and low resolutions.
- 8 GB system RAM is limited. Close other applications and use conservative batch sizes.
- The custom image is not an official AMD ROCm release for gfx803.
- Some optional ComfyUI nodes may fail because optional Python packages are not included.
- Installing the full upstream `requirements.txt`, arbitrary PyTorch builds, or PyPI `torchaudio` can replace or conflict with the custom ROCm stack.
- The tested PyPI torchaudio 2.1.2 package failed to load because it expected `libtorch_cuda.so`; it was removed.

## Do not do these things

- Do not install ROCm packages on the MX Linux host for this setup.
- Do not replace the host kernel or graphics driver just to follow generic ROCm instructions.
- Do not use `--privileged` for the ComfyUI container.
- Do not update the pinned image digest without testing the replacement.
- Do not assume every RX 580 board, kernel, Docker version, or Mesa version will behave identically.
