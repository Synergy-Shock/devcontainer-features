
# pnpm (pnpm)

Installs pnpm globally and configures the pnpm store directory and npm global prefix.

## Example Usage

```json
"features": {
    "ghcr.io/synergy-shock/devcontainer/pnpm:11": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select or enter the version of pnpm to install globally. | string | 11 |

## OS support

Debian/Ubuntu-based images with Node.js and `npm` pre-installed (e.g., the `mcr.microsoft.com/devcontainers/typescript-node` family).

## Implementation details

- `npm config set prefix /usr/local/share/npm-global` so global installs land in a system-wide location.
- `PNPM_HOME=/usr/local/share/pnpm` and `PNPM_STORE_DIR=/usr/local/share/pnpm-store`.
- `pnpm setup` is run under `SHELL=/bin/bash`.
- A `/etc/profile.d/pnpm.sh` snippet exports `NPM_CONFIG_PREFIX`, `PNPM_HOME`, `PNPM_STORE_DIR`, and prepends both bin dirs to `PATH` so login shells pick them up.
- The directories are `chown`-ed to `_REMOTE_USER` after install.

---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/Synergy-Shock/devcontainer/blob/main/src/pnpm/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
