## OS support

Debian/Ubuntu-based images with Node.js and `npm` pre-installed. The feature is self-sufficient: if `pnpm` is not already on `PATH`, it installs `pnpm@10` via `npm`. Pair with the [`pnpm`](../pnpm) feature when you want both tools sharing one configuration.

## What gets installed

- **opencode** — installed under `/usr/local/share/opencode` via the official installer (`https://opencode.ai/install`), symlinked to `/usr/local/bin/opencode`.
- **rtk** *(optional, default on)* — fetched from the latest GitHub release of `rtk-ai/rtk` and placed at `/usr/local/bin/rtk`.
- **@fission-ai/openspec** *(optional, default on)* — installed globally via `pnpm install -g`.

## Architectures

`x86_64` and `aarch64` (`arm64` is mapped to `aarch64`) for `rtk`.

## Why `installsAfter`/dependsOn aren't set

This feature configures the same `NPM_CONFIG_PREFIX`/`PNPM_HOME` paths as the [`pnpm`](../pnpm) feature, so it can run before or after `pnpm` without conflict.
