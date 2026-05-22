## OS support

Debian/Ubuntu-based images. The feature uses `apt-get` to install `curl`, `ca-certificates`, and `git`, then runs the official installer from `https://claude.ai/install.sh`.

## Implementation details

Claude Code is installed under `/usr/local/share/claude` (`$HOME` is redirected during install) so that bind-mounting `/home/<remoteUser>/.claude` from the host at runtime does not shadow the binaries. A symlink at `/usr/local/bin/claude` exposes the launcher on `PATH` without depending on shell rc files.

## Persist Claude auth and sessions across rebuilds

Bind `~/.claude` and `~/.claude.json` from the host so login state, project history, and memory survive container rebuilds — no re-authenticating after every `Rebuild Container`.

```jsonc
{
  "image": "mcr.microsoft.com/devcontainers/typescript-node:24-trixie",
  "features": {
    "ghcr.io/synergy-shock/devcontainer-features/claude:2": {}
  },
  "mounts": [
    "source=${localEnv:HOME}/.claude,target=/home/node/.claude,type=bind",
    "source=${localEnv:HOME}/.claude.json,target=/home/node/.claude.json,type=bind"
  ]
}
```
