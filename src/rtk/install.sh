#!/bin/bash
set -e

#-----------------------------------------------------------------------------------------------------
# rtk (Rust Token Killer) Dev Container Feature
# Installs the rtk CLI proxy from the latest (or pinned) rtk-ai/rtk GitHub release.
# Intended for use on Debian/Ubuntu-based images. Pairs well with the `claude` and `opencode` features.
#-----------------------------------------------------------------------------------------------------

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

RTK_VERSION="${VERSION:-latest}"

ARCH=$(uname -m)
case "${ARCH}" in
    x86_64)
        RTK_TARGET="x86_64-unknown-linux-musl"
        ;;
    aarch64|arm64)
        RTK_TARGET="aarch64-unknown-linux-gnu"
        ;;
    *)
        echo "(!) Architecture ${ARCH} is not supported for rtk."
        exit 1
        ;;
esac

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y --no-install-recommends curl jq ca-certificates
rm -rf /var/lib/apt/lists/*

echo "==> Installing rtk (${RTK_VERSION})..."
if [ "${RTK_VERSION}" = "latest" ]; then
    RTK_TAG=$(curl -fsSL https://api.github.com/repos/rtk-ai/rtk/releases/latest | jq -r '.tag_name')
else
    RTK_TAG="${RTK_VERSION}"
fi

RTK_URL="https://github.com/rtk-ai/rtk/releases/download/${RTK_TAG}/rtk-${RTK_TARGET}.tar.gz"
curl -fsSL "${RTK_URL}" | tar -xz -C /usr/local/bin rtk
chmod +x /usr/local/bin/rtk
rtk --version

echo "==> rtk feature installation complete!"
