
# GitButler CLI (gitbutler)

Installs the GitButler CLI (but).

## Example Usage

```json
"features": {
    "ghcr.io/synergy-shock/devcontainer-features/gitbutler:0": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Version of the GitButler CLI (but) to install. Use 'latest' to resolve the newest stable build_version at install time from https://app.gitbutler.com/api/downloads, or pin an explicit build_version (e.g. '0.19.13-3047') for byte-reproducible images. | string | latest |

## OS support

Debian/Ubuntu-based images with **glibc ≥ 2.32**. Verified on Debian 12+ (bookworm, trixie) and Ubuntu 22.04+ (jammy, noble). The upstream `but` binary links against newer glibc symbols, so older distros — notably Debian 11 (bullseye) and Ubuntu 20.04 (focal) — are not supported and will fail at load time with `GLIBC_2.32 not found`.

The feature installs `curl`, `libc6`, and `libdbus-1-3`, then downloads the prebuilt binary from `releases.gitbutler.com`.

## Architectures

`x86_64` and `aarch64` (the script maps `arm64` → `aarch64`). Anything else fails fast with a clear error.

## Source

Binaries come from `https://releases.gitbutler.com/releases/release/<version>/linux/<arch>/but` and are installed to `/usr/local/bin/but`.

## Version resolution

By default (`version: latest`) the install script queries `https://app.gitbutler.com/api/downloads?channel=release&limit=1` and installs the newest stable `build_version` it returns. Pass an explicit `build_version` (e.g. `0.19.13-3047`) to skip the lookup and pin the install — useful for byte-reproducible images or air-gapped rebuilds.

## Sign commits with the host SSH agent (macOS + 1Password)

GitButler shells out to `git` for fetch/push/sign, so it needs the host's SSH agent and signing helper. Forward Docker Desktop's SSH socket and bind-mount `op-ssh-sign` readonly so commits get signed against your 1Password key without copying private material into the container.

```jsonc
{
  "image": "mcr.microsoft.com/devcontainers/typescript-node:24-trixie",
  "features": {
    "ghcr.io/synergy-shock/devcontainer-features/gitbutler:0": {}
  },
  "mounts": [
    "source=/run/host-services/ssh-auth.sock,target=/agent.sock,type=bind",
    "source=/Applications/1Password.app/Contents/MacOS/op-ssh-sign,target=/op-ssh-sign,type=bind,readonly"
  ],
  "containerEnv": {
    "SSH_AUTH_SOCK": "/agent.sock"
  }
}
```

---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/Synergy-Shock/devcontainer-features/blob/main/src/gitbutler/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
