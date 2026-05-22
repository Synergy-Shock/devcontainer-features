## OS support

Debian/Ubuntu-based images with Node.js and `npm` pre-installed (e.g., the `mcr.microsoft.com/devcontainers/typescript-node` family).

## Implementation details

- `npm config set prefix /usr/local/share/npm-global` so global installs land in a system-wide location.
- `PNPM_HOME=/usr/local/share/pnpm` and `PNPM_STORE_DIR=/usr/local/share/pnpm-store`.
- `pnpm setup` is run under `SHELL=/bin/bash`.
- A `/etc/profile.d/pnpm.sh` snippet exports `NPM_CONFIG_PREFIX`, `PNPM_HOME`, `PNPM_STORE_DIR`, and prepends both bin dirs to `PATH` so login shells pick them up.
- The directories are `chown`-ed to `_REMOTE_USER` after install.

## Unify the pnpm store across devcontainers

Back the pnpm store with a Docker named volume and forward the host `~/.npmrc` readonly. Every devcontainer on the host then shares one cache — first install in a fresh container is fast, and registry/auth config stays on the host instead of being baked into images.

```jsonc
{
  "image": "mcr.microsoft.com/devcontainers/typescript-node:24-trixie",
  "features": {
    "ghcr.io/synergy-shock/devcontainer/pnpm:11": {}
  },
  "mounts": [
    "source=pnpm-store,target=/home/node/.pnpm-store,type=volume",
    "source=${localEnv:HOME}/.npmrc,target=/home/node/.npmrc,type=bind,readonly"
  ],
  "containerEnv": {
    "PNPM_HOME": "/home/node/.pnpm-store",
    "PNPM_STORE_DIR": "/home/node/.pnpm-store"
  }
}
```
