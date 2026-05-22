
# OpenCode (opencode)

Installs the OpenCode AI CLI.

## Example Usage

```json
"features": {
    "ghcr.io/synergy-shock/devcontainer/opencode:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Version selector (currently unused by the curl installer). | string | latest |

## OS support

Debian/Ubuntu-based images. The feature only relies on `curl`, `jq`, and `git` — no Node.js or `npm` required.

## What gets installed

- **opencode** — installed under `/usr/local/share/opencode` via the official installer (`https://opencode.ai/install`), symlinked to `/usr/local/bin/opencode`.

## Pairing with rtk

`rtk` is now a separate feature. Add `ghcr.io/synergy-shock/devcontainer/rtk` to your `devcontainer.json` alongside this one if you want both.

---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/Synergy-Shock/devcontainer/blob/main/src/opencode/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
