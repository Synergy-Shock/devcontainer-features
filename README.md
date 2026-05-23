# Synergy Shock Dev Container Features

A collection of [Dev Container Features](https://containers.dev/features) published to GHCR. Drop any of them into a `devcontainer.json` to get the same tooling we use internally.

## Features

| ID | Name | Description | Reference |
|----|------|-------------|-----------|
| [`claude`](./src/claude) | Claude Code | Installs the Claude Code CLI (`@anthropic-ai/claude-code`). | `ghcr.io/synergy-shock/devcontainer-features/claude` |
| [`gitbutler`](./src/gitbutler) | GitButler CLI | Installs the GitButler CLI (`but`). | `ghcr.io/synergy-shock/devcontainer-features/gitbutler` |
| [`node`](./src/node) | Node.js | Installs Node.js from the official nodejs.org prebuilt binaries, with optional `npm` and `pnpm` pinning. NVM-free. | `ghcr.io/synergy-shock/devcontainer-features/node` |
| [`opencode`](./src/opencode) | OpenCode | Installs the OpenCode AI CLI. | `ghcr.io/synergy-shock/devcontainer-features/opencode` |
| [`rtk`](./src/rtk) | rtk (Rust Token Killer) | Installs the `rtk` CLI proxy. Pairs with `claude` and/or `opencode`. | `ghcr.io/synergy-shock/devcontainer-features/rtk` |

## Usage

Reference a feature from any `devcontainer.json` by its GHCR URL and version tag:

```jsonc
{
  "image": "mcr.microsoft.com/devcontainers/base:trixie",
  "features": {
    "ghcr.io/synergy-shock/devcontainer-features/claude:2": {},
    "ghcr.io/synergy-shock/devcontainer-features/opencode:1": {},
    "ghcr.io/synergy-shock/devcontainer-features/rtk:0": {},
    "ghcr.io/synergy-shock/devcontainer-features/gitbutler:0": {}
  }
}
```

Version tags follow the `MAJOR`, `MAJOR.MINOR`, and `MAJOR.MINOR.PATCH` aliases that `devcontainers/action` publishes automatically.

## Recommended pairings

These features are intentionally narrow — one upstream CLI each. For everything else (a shell, language runtimes, git, GitHub auth), reach for **Microsoft's official base images** and the **`devcontainers/features`** catalog before writing your own. Both are first-party, versioned, and reviewed.

**Start from an official base image.** Pick the one that already ships the runtime you need so you don't reinstall it as a feature:

- [`mcr.microsoft.com/devcontainers/base:<distro>`](https://github.com/devcontainers/images/tree/main/src/base-debian) — minimal Debian/Ubuntu with `vscode` user, sudo, common utilities. The right default for our `claude` / `gitbutler` / `opencode` / `rtk` features, none of which need Node.
- [`mcr.microsoft.com/devcontainers/typescript-node:<node>-<distro>`](https://github.com/devcontainers/images/tree/main/src/typescript-node) — base + Node.js + `pnpm` and `yarn` via corepack, ships with a `node` user. Use this when you actually need a JS toolchain; it removes the need for any pnpm feature.

**Layer official features for shared tooling.** From [`ghcr.io/devcontainers/features`](https://github.com/devcontainers/features/tree/main/src):

- [`node:1`](https://github.com/devcontainers/features/tree/main/src/node) — install Node + npm, and pnpm via its `pnpmVersion` option (and yarn via `installYarnUsingApt`). NVM-based. Use it if you want NVM's multi-version management; reach for this repo's [`node`](./src/node) feature instead if you want a single, NVM-free Node install (official `nodejs.org` prebuilt binaries straight into `/usr/local`).
- [`common-utils:2`](https://github.com/devcontainers/features/tree/main/src/common-utils) — sudo, curl/wget, useful shells, the canonical non-root user setup. Add it when you start from a non-`devcontainers/base` image. **Required before** this repo's `node` feature.
- [`git:1`](https://github.com/devcontainers/features/tree/main/src/git) — newer git than what's in older distros.
- [`git-lfs:1`](https://github.com/devcontainers/features/tree/main/src/git-lfs) — Git LFS, if your repo uses it.
- [`github-cli:1`](https://github.com/devcontainers/features/tree/main/src/github-cli) — `gh` for PR/issue workflows and `gh auth` against the host.

A typical Node-flavored stack ends up looking like:

```jsonc
{
  "image": "mcr.microsoft.com/devcontainers/typescript-node:24-trixie",
  "features": {
    "ghcr.io/devcontainers/features/github-cli:1": {},
    "ghcr.io/devcontainers/features/git-lfs:1": {},
    "ghcr.io/synergy-shock/devcontainer-features/claude:2": {},
    "ghcr.io/synergy-shock/devcontainer-features/gitbutler:0": {}
  }
}
```

If you don't need Node at all, drop the image down to `mcr.microsoft.com/devcontainers/base:trixie` and skip the `node` feature entirely.

## Wiring host state into the container

The features install binaries; the `mounts` and `containerEnv` in this repo's own [`.devcontainer/devcontainer.json`](./.devcontainer/devcontainer.json) are a worked example of how to thread host credentials, caches, and services through so those binaries have something to talk to.

### Conventions worth copying

- **Bind host config, not container config.** Treat the container as disposable. Anything you would lose on rebuild (auth tokens, AI session state, shell history for the tools you care about) should live on the host and be mounted in.
- **Named volumes for caches.** Bind mounts share the host filesystem's permissions and inode layout, which is fine for config but slow and fragile for large package caches. Use a Docker named volume for anything write-heavy (a shared pnpm/yarn store, build caches, Docker layer caches inside the container).
- **`readonly` for credentials you only need to read.** `.npmrc` and the 1Password signing helper are mounted readonly so a misbehaving tool inside the container cannot corrupt host state.
- **Pair every socket bind with an env var.** A forwarded socket with no `SSH_AUTH_SOCK` (or equivalent) pointing at it is just a file.

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
node --version
opencode --version
pnpm --version
rtk --version
```

## Testing

Tests use the official `@devcontainers/cli`. Install it once:

```bash
npm install -g @devcontainers/cli
```

Then from the repo root:

```bash
# Autogenerated checks for a single feature
devcontainer features test -f claude \
  -i mcr.microsoft.com/devcontainers/base:trixie \
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
