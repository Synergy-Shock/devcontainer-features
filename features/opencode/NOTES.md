## OS support

Debian/Ubuntu-based images. The feature is self-contained — it fetches the
official opencode installer via `curl` and does not require Node.js or `npm`
on the host image.

## What gets installed

- **opencode** — installed under `/usr/local/share/opencode` via the official installer (`https://opencode.ai/install`), symlinked to `/usr/local/bin/opencode`.

## Pairing with rtk

`rtk` is now a separate feature. Add `ghcr.io/synergy-shock/devcontainer/rtk` to your `devcontainer.json` alongside this one if you want both.
