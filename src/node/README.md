
# Node.js (node)

Installs Node.js from the official nodejs.org prebuilt binaries, with optional npm and pnpm pinning. Assumes 'ghcr.io/devcontainers/features/common-utils:2' has run.

## Example Usage

```json
"features": {
    "ghcr.io/synergy-shock/devcontainer-features/node:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Node.js version. 'lts' (default), 'latest'/'current', an lts codename ('lts/krypton'), a major ('24'), a major.minor ('24.16'), or an exact version ('24.16.0' / 'v24.16.0'). | string | lts |
| npmVersion | npm version (passed to 'npm install -g npm@<value>'). Use 'latest' for the newest, or pin (e.g. '11.15.0'). | string | latest |
| pnpmVersion | pnpm version. Installed via the official 'https://get.pnpm.io/install.sh' script (PNPM_HOME=/usr/local/share/pnpm, symlinked to /usr/local/bin/pnpm). Use 'latest' for the newest, or pin (e.g. '11.2.2'). | string | latest |

## OS support

Debian/Ubuntu-based images. The feature does **not** call `apt-get` itself — it expects `curl`, `jq`, and `tar` to already be installed. The expected provider is [`ghcr.io/devcontainers/features/common-utils:2`](https://github.com/devcontainers/features/tree/main/src/common-utils), which must be listed **before** the `node` feature in your `devcontainer.json`. If any required command is missing, the install script aborts with a clear error pointing at `common-utils:2`.

## Implementation details

- **Node.js** is the official Linux prebuilt tarball from `https://nodejs.org/dist/`, extracted into `/usr/local` with `tar --strip-components=1 --exclude=CHANGELOG.md --exclude=LICENSE --exclude=README.md` so that `node`, `npm`, and `npx` land directly under `/usr/local/bin` — already on every shell's `PATH`. No NVM, no NodeSource apt repo, no shell-rc edits.
- **Version resolution** is done against the official `https://nodejs.org/dist/index.json` index. Accepted forms for the `version` option: `lts`, `latest`/`current`, `lts/<codename>` (e.g. `lts/krypton`), `<major>` (e.g. `24`), `<major>.<minor>`, or an exact version with or without a leading `v`.
- **npm** is pinned with `npm install -g npm@<version>`. The default `latest` always installs the newest published npm.
- **pnpm** is installed via the official `https://get.pnpm.io/install.sh` script (documented at <https://pnpm.io/installation>). It runs with `PNPM_HOME=/usr/local/share/pnpm` and the binary is symlinked to `/usr/local/bin/pnpm` so it lands on every shell's `PATH` without needing the rc-file shim. The `pnpmVersion` option is passed via the `PNPM_VERSION` env var (omitted when set to `latest`). No Corepack indirection.

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

---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/Synergy-Shock/devcontainer-features/blob/main/src/node/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
