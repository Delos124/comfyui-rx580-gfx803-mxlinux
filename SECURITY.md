# Security policy

## Supported configuration

This repository documents a local ComfyUI deployment. The default container port is bound to `127.0.0.1`, so it is reachable only from the local machine.

Do not expose ComfyUI directly to the public internet. ComfyUI and third-party custom nodes can execute code and should be treated as trusted software only when obtained from sources you have reviewed.

## Reporting a security issue

Do not publish secrets, access tokens, private keys, personal data, or unredacted diagnostic logs in public issues. For sensitive reports, contact the repository maintainer through GitHub's private vulnerability reporting feature if it is enabled.

## Supply-chain notes

The installation uses a third-party container image pinned by digest. Review the image publisher and source before use. Custom nodes and model files are separate third-party components and may have their own security and licensing risks.
