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

BUT_VERSION="${VERSION:-latest}"

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
apt-get install -y --no-install-recommends curl jq libc6 libdbus-1-3
rm -rf /var/lib/apt/lists/*

if [ "${BUT_VERSION}" = "latest" ]; then
    echo "==> Resolving latest stable GitButler build..."
    BUT_VERSION=$(curl -fsSL 'https://app.gitbutler.com/api/downloads?channel=release&limit=1' \
        | jq -r '.[0].build_version')
    if [ -z "${BUT_VERSION}" ] || [ "${BUT_VERSION}" = "null" ]; then
        echo "(!) Failed to resolve latest GitButler version from app.gitbutler.com/api/downloads"
        exit 1
    fi
    echo "==> Resolved latest = ${BUT_VERSION}"
fi

echo "==> Installing GitButler CLI (but) v${BUT_VERSION} for ${BUT_ARCH}..."
BUT_URL="https://releases.gitbutler.com/releases/release/${BUT_VERSION}/linux/${BUT_ARCH}/but"
BUT_BIN="/usr/local/bin/but"

curl -fsSL -o "${BUT_BIN}" "${BUT_URL}"
chmod +x "${BUT_BIN}"
"${BUT_BIN}" --version

if [ -n "${_REMOTE_USER:-}" ] && [ "${_REMOTE_USER}" != "root" ]; then
    REMOTE_USER_HOME="${_REMOTE_USER_HOME:-/home/${_REMOTE_USER}}"
    GITBUTLER_DATA_DIR="${REMOTE_USER_HOME}/.local/share/com.gitbutler.app"
    echo "==> Pre-creating ${GITBUTLER_DATA_DIR} for ${_REMOTE_USER}..."
    mkdir -p "${GITBUTLER_DATA_DIR}"
    chown -R "${_REMOTE_USER}:${_REMOTE_USER}" \
        "${REMOTE_USER_HOME}/.local" \
        "${REMOTE_USER_HOME}/.local/share" \
        "${GITBUTLER_DATA_DIR}"
fi

echo "==> GitButler feature installation complete!"
