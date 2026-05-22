# Synergy Shock Dev Container Features

A collection of [Dev Container Features](https://containers.dev/features) published to GHCR. Drop any of them into a `devcontainer.json` to get the same tooling we use internally.

## Features

| ID | Name | Description | Reference |
|----|------|-------------|-----------|
| [`claude`](./src/claude) | Claude Code | Installs the Claude Code CLI (`@anthropic-ai/claude-code`). | `ghcr.io/synergy-shock/devcontainer-features/claude` |
| [`gitbutler`](./src/gitbutler) | GitButler CLI | Installs the GitButler CLI (`but`). | `ghcr.io/synergy-shock/devcontainer-features/gitbutler` |
| [`opencode`](./src/opencode) | OpenCode | Installs the OpenCode AI CLI. | `ghcr.io/synergy-shock/devcontainer-features/opencode` |
| [`pnpm`](./src/pnpm) | pnpm | Installs pnpm globally and configures the store and npm prefix. | `ghcr.io/synergy-shock/devcontainer-features/pnpm` |
| [`rtk`](./src/rtk) | rtk (Rust Token Killer) | Installs the `rtk` CLI proxy. Pairs with `claude` and/or `opencode`. | `ghcr.io/synergy-shock/devcontainer-features/rtk` |

## Usage

Reference a feature from any `devcontainer.json` by its GHCR URL and version tag:

```jsonc
{
  "image": "mcr.microsoft.com/devcontainers/typescript-node:24-trixie",
  "features": {
    "ghcr.io/synergy-shock/devcontainer-features/pnpm:11": {},
    "ghcr.io/synergy-shock/devcontainer-features/claude:2": {},
    "ghcr.io/synergy-shock/devcontainer-features/opencode:1": {},
    "ghcr.io/synergy-shock/devcontainer-features/rtk:0": {},
    "ghcr.io/synergy-shock/devcontainer-features/gitbutler:0": {}
  }
}
```

Version tags follow the `MAJOR`, `MAJOR.MINOR`, and `MAJOR.MINOR.PATCH` aliases that `devcontainers/action` publishes automatically.

## Wiring host state into the container

The features install binaries; the `mounts` and `containerEnv` in this repo's own [`.devcontainer/devcontainer.json`](./.devcontainer/devcontainer.json) are a worked example of how to thread host credentials, caches, and services through so those binaries have something to talk to.

### Conventions worth copying

- **Bind host config, not container config.** Treat the container as disposable. Anything you would lose on rebuild (auth tokens, AI session state, shell history for the tools you care about) should live on the host and be mounted in.
- **Named volumes for caches.** Bind mounts share the host filesystem's permissions and inode layout, which is fine for config but slow and fragile for large package caches. Use a Docker named volume (like `pnpm-store` below) for anything write-heavy.
- **`readonly` for credentials you only need to read.** `.npmrc` and the 1Password signing helper are mounted readonly so a misbehaving tool inside the container cannot corrupt host state.
- **Pair every socket bind with an env var.** A forwarded socket with no `SSH_AUTH_SOCK` (or equivalent) pointing at it is just a file.

### Forward PNPM configuration to all devcontainers

Mount the host's `~/.npmrc` readonly so the container inherits your registry, auth tokens, and pnpm settings without copying secrets into the image. `PNPM_HOME` and `PNPM_STORE_DIR` keep the store path predictable across rebuilds.

```jsonc
{
  "image": "mcr.microsoft.com/devcontainers/typescript-node:24-trixie",
  "features": {
    "ghcr.io/synergy-shock/devcontainer-features/pnpm:11": {}
  },
  "mounts": [
    "source=${localEnv:HOME}/.npmrc,target=/home/node/.npmrc,type=bind,readonly",
  ],
  "containerEnv": {
    "PNPM_HOME": "/home/node/.pnpm-store",
    "PNPM_STORE_DIR": "/home/node/.pnpm-store"
  }
}
```

### Unify PNPM cache across all devcontainers

Back the pnpm store with a Docker named volume so every devcontainer on the host shares one cache — first install in a fresh container is fast, and disk usage stops scaling with the number of projects.

```jsonc
{
  "image": "mcr.microsoft.com/devcontainers/typescript-node:24-trixie",
  "features": {
    "ghcr.io/synergy-shock/devcontainer-features/pnpm:11": {}
  },
  "mounts": [
    "source=pnpm-store,target=/home/node/.pnpm-store,type=volume",
  ],
  "containerEnv": {
    "PNPM_HOME": "/home/node/.pnpm-store",
    "PNPM_STORE_DIR": "/home/node/.pnpm-store"
  }
}
```

### 1Password SSH agent and commit signing (macOS)

On macOS, Docker Desktop forwards the host SSH agent socket to `/run/host-services/ssh-auth.sock`. Bind it into the container and point `SSH_AUTH_SOCK` at it so `ssh` and `git` can use keys held by 1Password without copying them into the container. The `op-ssh-sign` helper is bind-mounted readonly so commits can be signed against a 1Password-managed key — configure git to invoke it via `gpg.ssh.program`.

```jsonc
{
  "image": "mcr.microsoft.com/devcontainers/typescript-node:24-trixie",
  "features": {
    "ghcr.io/synergy-shock/devcontainer-features/claude:2": {}
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

## Local development

This repo's own `.devcontainer/devcontainer.json` composes features from `../src/<id>` so contributors can iterate on the install scripts in-place. Open the repo in VS Code Dev Containers, or run:

```bash
devcontainer up --workspace-folder .
```

Then inside the container verify the binaries you touched:

```bash
claude --version
but --version
opencode --version
pnpm --version
```

## Testing

Tests use the official `@devcontainers/cli`. Install it once:

```bash
npm install -g @devcontainers/cli
```

Then from the repo root:

```bash
# Autogenerated checks for a single feature
devcontainer features test -f pnpm \
  -i mcr.microsoft.com/devcontainers/typescript-node:24-trixie \
  -p .

# Custom scenarios for a single feature
devcontainer features test -f opencode --skip-autogenerated -p .

# Cross-feature combinations
devcontainer features test --global-scenarios-only -p .
```

Each per-feature test lives at `test/<id>/test.sh`; scenario tests at `test/<id>/<scenario>.sh` with the matching `test/<id>/scenarios.json`; cross-feature tests in `test/_global/`.

CI runs all three of these in `.github/workflows/test.yaml` on every push and PR.

## Releasing

1. Bump `version` in `src/<id>/devcontainer-feature.json` for any feature you changed. Follow SemVer.
2. Merge the PR to `main`.
3. From the **Actions** tab, run the **Release features** workflow (`workflow_dispatch`). It will:
   - publish each feature to `ghcr.io/synergy-shock/devcontainer-features/<id>` with the new version tag
   - open a follow-up PR with auto-generated `src/<id>/README.md` updates
4. **First-time only**, visit <https://github.com/orgs/Synergy-Shock/packages> (or your account `?tab=packages` if published under a user namespace), open each new package, and change its visibility to **public**. GHCR publishes private by default.

## Contributing

- Author hand-written context in `src/<id>/NOTES.md` — it gets concatenated into the auto-generated `README.md` so consumers see it.
- Don't edit `src/<id>/README.md` by hand; the release workflow regenerates it.
- Run the relevant `devcontainer features test` locally before opening a PR.

## License

MIT — see [LICENSE](./LICENSE).
