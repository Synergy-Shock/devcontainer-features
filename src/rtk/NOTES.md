## OS support

Debian/Ubuntu-based images. The feature only relies on `curl`, `jq`, and `ca-certificates`.

## What gets installed

- **rtk** — fetched from the latest (or pinned via `version`) GitHub release of `rtk-ai/rtk` and placed at `/usr/local/bin/rtk`.

## Architectures

`x86_64` (musl) and `aarch64` (gnu). `arm64` is mapped to `aarch64`.

## Pairing

Composes naturally with the `claude` and `opencode` features in the same `devcontainer.json` — install whichever assistants you use alongside `rtk`.
