
# OpenCode (opencode)

Installs the OpenCode AI CLI.

## Example Usage

```json
"features": {
    "ghcr.io/synergy-shock/devcontainer-features/opencode:1": {}
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

`rtk` is now a separate feature. Add `ghcr.io/synergy-shock/devcontainer-features/rtk` to your `devcontainer.json` alongside this one if you want both.

## Persist OpenCode config and data across rebuilds

Bind `~/.config/opencode` and `~/.local/share/opencode` from the host so credentials, model preferences, and conversation history survive container rebuilds.

```jsonc
{
  "image": "mcr.microsoft.com/devcontainers/typescript-node:24-trixie",
  "features": {
    "ghcr.io/synergy-shock/devcontainer-features/opencode:1": {}
  },
  "mounts": [
    "source=${localEnv:HOME}/.config/opencode,target=/home/node/.config/opencode,type=bind",
    "source=${localEnv:HOME}/.local/share/opencode,target=/home/node/.local/share/opencode,type=bind"
  ]
}
```

---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/Synergy-Shock/devcontainer-features/blob/main/src/opencode/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
