## OS support

Debian/Ubuntu-based images with **glibc ≥ 2.32**. Verified on Debian 12+ (bookworm, trixie) and Ubuntu 22.04+ (jammy, noble). The upstream `but` binary links against newer glibc symbols, so older distros — notably Debian 11 (bullseye) and Ubuntu 20.04 (focal) — are not supported and will fail at load time with `GLIBC_2.32 not found`.

The feature installs `curl`, `libc6`, and `libdbus-1-3`, then downloads the prebuilt binary from `releases.gitbutler.com`.

## Architectures

`x86_64` and `aarch64` (the script maps `arm64` → `aarch64`). Anything else fails fast with a clear error.

## Source

Binaries come from `https://releases.gitbutler.com/releases/release/<version>/linux/<arch>/but` and are installed to `/usr/local/bin/but`.
