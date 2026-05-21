#!/bin/bash
set -e

#-----------------------------------------------------------------------------------------------------
# GitButler Dev Container Feature
# Installs: the GitButler CLI (but)
# Intended for use on Debian/Ubuntu-based images
#-----------------------------------------------------------------------------------------------------

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

BUT_VERSION="${VERSION:-0.19.12-3040}"

ARCH=$(uname -m)
case "${ARCH}" in
    x86_64)
        BUT_ARCH="x86_64"
        ;;
    aarch64|arm64)
        BUT_ARCH="aarch64"
        ;;
    *)
        echo "(!) Architecture ${ARCH} is not supported for the 'but' binary."
        exit 1
        ;;
esac

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y --no-install-recommends curl libc6 libdbus-1-3
rm -rf /var/lib/apt/lists/*

echo "==> Installing GitButler CLI (but) v${BUT_VERSION} for ${BUT_ARCH}..."
BUT_URL="https://releases.gitbutler.com/releases/release/${BUT_VERSION}/linux/${BUT_ARCH}/but"
BUT_BIN="/usr/local/bin/but"

curl -fsSL -o "${BUT_BIN}" "${BUT_URL}"
chmod +x "${BUT_BIN}"
"${BUT_BIN}" --version

echo "==> GitButler feature installation complete!"
