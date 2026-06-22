## OS support

Debian/Ubuntu-based images (any CPU: `x86_64` / `aarch64`). The feature does **not** call `apt-get` itself — it expects `curl`, `jq`, `tar`, and `sha256sum` to already be installed. The expected provider is [`ghcr.io/devcontainers/features/common-utils:2`](https://github.com/devcontainers/features/tree/main/src/common-utils), which must be listed **before** the `fresh` feature in your `devcontainer.json`. If any required command is missing, the install script aborts with a clear error pointing at `common-utils:2`.

Because it installs the statically-linked **musl** build, it does not depend on the host's glibc version and runs identically on slim and full base images, as root or as a non-root `remoteUser`.

## Implementation details

- **Fresh** is the official prebuilt binary from the [`sinelaw/fresh` GitHub releases](https://github.com/sinelaw/fresh/releases). The feature downloads the `fresh-editor-<arch>-unknown-linux-musl.tar.gz` asset (static musl build) and extracts **only** the `fresh` binary into `/usr/local/bin` — already on every shell's `PATH`. The bundled `LICENSE`, `README.md`, `fresh.desktop`, and `icons/` are intentionally left out, since a devcontainer only needs the executable. No AppImage, no `.deb`, no Cargo/npm build.
- **Version resolution**: `latest` (the default) queries `https://api.github.com/repos/sinelaw/fresh/releases/latest` for the newest release tag. A pinned value (`0.4.1` or `v0.4.1`) is used verbatim as the release tag. Asset filenames carry no version string, so only the tag is needed for the download URL.
- **Checksum verification**: the matching `<asset>.sha256` is downloaded alongside the tarball and compared with `sha256sum` before extraction; a mismatch aborts the install.
- **Architecture**: `x86_64` and `aarch64`/`arm64` map to the upstream `x86_64` and `aarch64` musl assets. Other architectures abort with a clear error.
- **Optional `GITHUB_TOKEN`**: if present in the environment, it is sent as a bearer token on the GitHub API call to lift the anonymous rate limit. It is never required.

## Feature ordering

Add `common-utils` **before** `fresh`, since this feature checks its dependencies up front:

```jsonc
{
  "image": "mcr.microsoft.com/devcontainers/base:trixie",
  "features": {
    "ghcr.io/devcontainers/features/common-utils:2": {},
    "ghcr.io/synergy-shock/devcontainer-features/fresh:1": {
      "version": "latest"
    }
  }
}
```

If you already start from `mcr.microsoft.com/devcontainers/base:*`, `common-utils` essentials are baked in; the explicit feature line is still the safest way to guarantee `curl` / `jq` / `tar` / `sha256sum` regardless of the base image.
