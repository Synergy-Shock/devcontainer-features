#!/bin/bash
set -e

#-----------------------------------------------------------------------------------------------------
# OpenCode Dev Container Feature
# Installs: opencode-ai, rtk
# Intended for use on Debian/Ubuntu-based images. Does not require Node.js.
#-----------------------------------------------------------------------------------------------------

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

OPENCODE_VERSION="${VERSION:-latest}"
INSTALL_RTK="${INSTALLRTK:-true}"

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
apt-get install -y --no-install-recommends curl jq git
rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------------
# Install rtk (optional)
# ------------------------------------------------------------------
if [ "${INSTALL_RTK}" = "true" ]; then
    echo "==> Installing rtk..."
    RTK_LATEST=$(curl -fsSL https://api.github.com/repos/rtk-ai/rtk/releases/latest | jq -r '.tag_name')
    RTK_URL="https://github.com/rtk-ai/rtk/releases/download/${RTK_LATEST}/rtk-${RTK_TARGET}.tar.gz"
    curl -fsSL "${RTK_URL}" | tar -xz -C /usr/local/bin rtk
    chmod +x /usr/local/bin/rtk
    rtk --version
else
    echo "==> Skipping rtk installation."
fi

# ------------------------------------------------------------------
# Install opencode
# ------------------------------------------------------------------
echo "==> Installing opencode..."
# Install into a system-wide HOME and expose the launcher without relying on shell rc files.
OPENCODE_INSTALL_HOME="/usr/local/share/opencode"
mkdir -p "${OPENCODE_INSTALL_HOME}"
curl -fsSL https://opencode.ai/install | env -u VERSION HOME="${OPENCODE_INSTALL_HOME}" bash -s -- --no-modify-path
ln -sf "${OPENCODE_INSTALL_HOME}/.opencode/bin/opencode" /usr/local/bin/opencode
opencode --version

echo "==> Adjusting permissions for ${_REMOTE_USER} user..."
chown -R "${_REMOTE_USER}:${_REMOTE_USER}" "${OPENCODE_INSTALL_HOME}" 2>/dev/null || true

echo "==> Pre-creating XDG directories for ${_REMOTE_USER} user..."
mkdir -p "${_REMOTE_USER_HOME}/.config" "${_REMOTE_USER_HOME}/.local"
chown -R "${_REMOTE_USER}:${_REMOTE_USER}" "${_REMOTE_USER_HOME}"

echo "==> OpenCode feature installation complete!"
