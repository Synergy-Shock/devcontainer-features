## OS support

Debian/Ubuntu-based images. The feature uses `apt-get` to install `curl`, `ca-certificates`, and `git`, then runs the official installer from `https://claude.ai/install.sh`.

## Implementation details

Claude Code is installed under `/usr/local/share/claude` (`$HOME` is redirected during install) so that bind-mounting `/home/<remoteUser>/.claude` from the host at runtime does not shadow the binaries. A symlink at `/usr/local/bin/claude` exposes the launcher on `PATH` without depending on shell rc files.
