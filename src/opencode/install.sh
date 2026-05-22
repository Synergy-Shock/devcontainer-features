#!/bin/bash
set -e

#-----------------------------------------------------------------------------------------------------
# OpenCode Dev Container Feature
# Installs: opencode-ai
# Intended for use on Debian/Ubuntu-based images. Does not require Node.js.
#-----------------------------------------------------------------------------------------------------

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

OPENCODE_VERSION="${VERSION:-latest}"

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y --no-install-recommends curl jq git
rm -rf /var/lib/apt/lists/*

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
