# IP-Adapter on the RX 580 (gfx803)

This guide records the optional IP-Adapter setup verified with the repository's ComfyUI v0.2.7 container. It does not make IP-Adapter part of the base installation.

## Verified environment

- ComfyUI: v0.2.7, running in the pinned gfx803 Docker image.
- Extension folder: `ComfyUI_IPAdapter_plus_old`.
- Extension source: [meimeilook/ComfyUI_IPAdapter_plus.old](https://github.com/meimeilook/ComfyUI_IPAdapter_plus.old), a fork of [cubiq/ComfyUI_IPAdapter_plus](https://github.com/cubiq/ComfyUI_IPAdapter_plus).
- Reproducible upstream revision: `ebd80fd896e738085ae139a4f31c76f4c3f1af08`.
- Verified registered node IDs include `old_IPAdapterModelLoader`, `old_IPAdapterApply`, `old_IPAdapterTilesMasked`, `old_IPAdapterApplyFaceID`, `old_IPAdapterApplyEncoded`, `old_IPAdapterEncoder`, `old_IPAdapterSaveEmbeds`, `old_IPAdapterLoadEmbeds`, and `old_IPAdapterBatchEmbeds`.

The `old_` prefix is intentional: this fork preserves the older node implementation and exposes its nodes under distinct names. Existing workflows must use the node IDs actually registered by this fork.

## Install the extension

The base installer intentionally does not install optional custom nodes. Install this known-compatible historical fork with the repository helper:

```bash
bash ./scripts/install-ipadapter.sh
```

The helper clones the pinned upstream revision only when the target directory does not exist. If the directory already exists, it verifies the remote and revision and refuses to overwrite or modify it.

If that directory already exists, do not clone over it. Inspect it first:

```bash
git -C "$ROOT/custom_nodes/ComfyUI_IPAdapter_plus_old" remote -v
git -C "$ROOT/custom_nodes/ComfyUI_IPAdapter_plus_old" status --short
git -C "$ROOT/custom_nodes/ComfyUI_IPAdapter_plus_old" rev-parse HEAD
```

Restart ComfyUI after installing or changing a custom node:

```bash
./scripts/stop.sh
./scripts/start.sh
```

Do not install a second IP-Adapter extension alongside this fork unless you deliberately manage node-name collisions and workflow compatibility.

## Model files

For the SD 1.5 base IP-Adapter model, place:

- `ip-adapter_sd15.safetensors` in `models/ipadapter/`
- `CLIP-ViT-H-14-laion2B-s32B-b79K.safetensors` in `models/clip_vision/`

The IP-Adapter weight is not the image encoder. Both files are required for the standard SD 1.5 IP-Adapter workflow. The model-to-encoder pairing matters: this base SD 1.5 model uses the ViT-H encoder, not the SDXL ViT-bigG encoder.

Official model source: [h94/IP-Adapter on Hugging Face](https://huggingface.co/h94/IP-Adapter). Download model weights directly from their publisher; this repository does not redistribute weights. Review the applicable model license before use.

Create the model directories if they do not already exist:

```bash
ROOT="$(<.comfyui-root)"
mkdir -p "$ROOT/models/ipadapter" "$ROOT/models/clip_vision"
```

The ViT-H encoder is published as `model.safetensors`; download it and save it under the required descriptive filename:

```bash
wget -O "$ROOT/models/clip_vision/CLIP-ViT-H-14-laion2B-s32B-b79K.safetensors" \
  "https://huggingface.co/h94/IP-Adapter/resolve/main/models/image_encoder/model.safetensors"
```

Keep the downloaded file in the model directory only; do not add it to Git.

The current RX 580 installation has confirmed the IP-Adapter model at:

`/workspace/comfyui/app/models/ipadapter/ip-adapter_sd15.safetensors`

The ViT-H CLIP Vision encoder is confirmed present in the active installation at `models/clip_vision/CLIP-ViT-H-14-laion2B-s32B-b79K.safetensors`. The verifier requires this file because the standard SD 1.5 base IP-Adapter workflow cannot run without it.

## Verify registration and model files

From the cloned repository root, run:

```bash
bash ./scripts/verify-ipadapter.sh
```

The check verifies the pinned extension source and revision, requires both model files, and queries ComfyUI's local `/object_info` API for the legacy IP-Adapter nodes plus `CLIPVisionLoader` and `CLIPVisionEncode`.

A successful node-registration check does not prove that a workflow can load the encoder or complete image generation. Complete a basic SD 1.5 IP-Adapter workflow before treating generation as validated.

## First workflow test

Use the existing SD 1.5 checkpoint and a square reference image. In ComfyUI:

1. Load the SD 1.5 checkpoint.
2. Load the reference image.
3. Load the CLIP Vision model using the available CLIP Vision loader.
4. Use `old_IPAdapterModelLoader` and select `ip-adapter_sd15.safetensors`.
5. Connect the model, reference image, CLIP Vision output, and IP-Adapter model through the compatible legacy apply node exposed by this fork.
6. Connect the resulting model conditioning to the KSampler and generate a small test image.

Use a conservative resolution such as 512×512 and a modest step count on the 4 GB RX 580. Avoid FaceID nodes for the first test: FaceID has additional InsightFace/model requirements and is not needed for basic reference-image conditioning.

## Troubleshooting

### The standalone Python check says `KeyError: 'ipadapter'`

Do not use a separate Python process importing only `folder_paths` as proof that the running ComfyUI server lacks the category. Custom-node registration occurs when ComfyUI imports the extension at startup. Query the running server's `/object_info` API instead:

```bash
curl -fsS http://127.0.0.1:8188/object_info | python3 -c 'import json,sys; d=json.load(sys.stdin); print(chr(10).join(k for k in d if "ipadapter" in k.lower()))'
```

### The model loader has no selectable models

Check the file is under the active ComfyUI model root at `models/ipadapter/`, then restart ComfyUI. The legacy extension registers the `ipadapter` category during its import.

### Shape mismatch or encoder errors

Check that the checkpoint is SD 1.5, the IP-Adapter file is `ip-adapter_sd15.safetensors`, and the CLIP Vision model is the ViT-H encoder. Do not pair the SD 1.5 base model with the ViT-bigG encoder.

### FaceID nodes fail

FaceID is separate from basic IP-Adapter. It requires additional InsightFace support and compatible FaceID model/LoRA files. Do not install those dependencies unless FaceID is specifically required.

## Compatibility and maintenance notes

This is a legacy extension fork intended for the pinned ComfyUI v0.2.7 environment. It is not a recommendation to update ComfyUI or the custom node independently. Preserve the pinned extension revision and test the complete workflow before changing either ComfyUI or PyTorch/ROCm components.
