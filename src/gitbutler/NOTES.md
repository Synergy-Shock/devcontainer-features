## OS support

Debian/Ubuntu-based images. The feature installs `curl`, `libc6`, and `libdbus-1-3`, then downloads a static binary.

## Architectures

`x86_64` and `aarch64` (the script maps `arm64` → `aarch64`). Anything else fails fast with a clear error.

## Source

Binaries come from `https://releases.gitbutler.com/releases/release/<version>/linux/<arch>/but` and are installed to `/usr/local/bin/but`.
