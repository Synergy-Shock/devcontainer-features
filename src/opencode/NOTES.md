## OS support

Debian/Ubuntu-based images. The feature only relies on `curl`, `jq`, and `git` — no Node.js or `npm` required.

## What gets installed

- **opencode** — installed under `/usr/local/share/opencode` via the official installer (`https://opencode.ai/install`), symlinked to `/usr/local/bin/opencode`.
- **rtk** *(optional, default on)* — fetched from the latest GitHub release of `rtk-ai/rtk` and placed at `/usr/local/bin/rtk`.

## Architectures

`x86_64` and `aarch64` (`arm64` is mapped to `aarch64`) for `rtk`.
