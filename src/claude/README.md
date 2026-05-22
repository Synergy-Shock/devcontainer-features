
# Claude Code (claude)

Installs the Claude Code CLI (@anthropic-ai/claude-code).

## Example Usage

```json
"features": {
    "ghcr.io/synergy-shock/devcontainer/claude:2": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select or enter the version of @anthropic-ai/claude-code to install globally. | string | latest |

## OS support

Debian/Ubuntu-based images. The feature uses `apt-get` to install `curl`, `ca-certificates`, and `git`, then runs the official installer from `https://claude.ai/install.sh`.

## Implementation details

Claude Code is installed under `/usr/local/share/claude` (`$HOME` is redirected during install) so that bind-mounting `/home/<remoteUser>/.claude` from the host at runtime does not shadow the binaries. A symlink at `/usr/local/bin/claude` exposes the launcher on `PATH` without depending on shell rc files.

---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/Synergy-Shock/devcontainer/blob/main/src/claude/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
