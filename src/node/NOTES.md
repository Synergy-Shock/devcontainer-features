## OS support

Debian/Ubuntu-based images. The feature does **not** call `apt-get` itself — it expects `curl`, `jq`, and `tar` to already be installed. The expected provider is [`ghcr.io/devcontainers/features/common-utils:2`](https://github.com/devcontainers/features/tree/main/src/common-utils), which must be listed **before** the `node` feature in your `devcontainer.json`. If any required command is missing, the install script aborts with a clear error pointing at `common-utils:2`.

## Implementation details

- **Node.js** is the official Linux prebuilt tarball from `https://nodejs.org/dist/`, extracted into `/usr/local` with `tar --strip-components=1 --exclude=CHANGELOG.md --exclude=LICENSE --exclude=README.md` so that `node`, `npm`, and `npx` land directly under `/usr/local/bin` — already on every shell's `PATH`. No NVM, no NodeSource apt repo, no shell-rc edits.
- **Version resolution** is done against the official `https://nodejs.org/dist/index.json` index. Accepted forms for the `version` option: `lts`, `latest`/`current`, `lts/<codename>` (e.g. `lts/krypton`), `<major>` (e.g. `24`), `<major>.<minor>`, or an exact version with or without a leading `v`.
- **npm** is pinned with `npm install -g npm@<version>` into the Node tarball's `/usr/local` prefix, overwriting `/usr/local/bin/npm`. The default `latest` always installs the newest published npm.
- **pnpm** is installed with `npm install -g pnpm@<version>` (no `get.pnpm.io` script, no Corepack indirection). It lands in `NPM_CONFIG_PREFIX` — a dedicated dir for npm globals so user-installed packages don't mix with the Node tarball's `/usr/local/bin` — and is symlinked at `/usr/local/bin/pnpm` so it's reachable even before `/etc/profile.d/node.sh` is sourced. The install script writes `/etc/profile.d/node.sh` exporting `NPM_CONFIG_PREFIX`, `PNPM_HOME` (where pnpm itself stores globally-installed packages on later `pnpm add -g …`), and prepending both `${NPM_CONFIG_PREFIX}/bin` and `${PNPM_HOME}` to `PATH`. `/etc/profile` is sourced by login shells, and `common-utils:2` (a prerequisite) also wires `/etc/bash.bashrc` to source `/etc/profile.d/*.sh`, so the binaries are reachable from both login and interactive non-login shells.
- **Location of `NPM_CONFIG_PREFIX` / `PNPM_HOME`** depends on whether a non-root remote user is configured:
  - **Non-root `remoteUser`** (e.g. `vscode`): `${_REMOTE_USER_HOME}/.local/share/npm-global` and `${_REMOTE_USER_HOME}/.local/share/pnpm`. Keeping them under the user's `HOME` lets non-root `pnpm install` write the SQLite store index (WAL files) without "readonly database" errors, and survives layer caching in a user-owned tree.
  - **No remote user or `root`**: falls back to `/usr/local/share/npm-global` and `/usr/local/share/pnpm`.
  Both paths are baked into `/etc/profile.d/node.sh` at install time and chowned to `_REMOTE_USER` when set.

## Feature ordering

Add `common-utils` **before** `node`, since this feature checks its dependencies up front:

```jsonc
{
  "image": "mcr.microsoft.com/devcontainers/base:trixie",
  "features": {
    "ghcr.io/devcontainers/features/common-utils:2": {},
    "ghcr.io/synergy-shock/devcontainer-features/node:0": {
      "version": "lts",
      "npmVersion": "latest",
      "pnpmVersion": "latest"
    }
  }
}
```

If you already start from `mcr.microsoft.com/devcontainers/base:*`, `common-utils` essentials are baked in; the explicit feature line is still the safest way to guarantee `curl` / `jq` / `tar` regardless of the base image.
