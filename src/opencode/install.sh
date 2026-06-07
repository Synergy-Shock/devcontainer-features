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

# ------------------------------------------------------------------
# Resolve the target user and home directory.
# The dev container CLI normally injects _REMOTE_USER / _REMOTE_USER_HOME,
# but they can be empty depending on the build context — derive sane
# fallbacks so chown/mkdir never run against an empty path.
# ------------------------------------------------------------------
if [ -z "${_REMOTE_USER}" ]; then
    _REMOTE_USER="$(id -un 1000 2>/dev/null || echo root)"
fi

if [ -z "${_REMOTE_USER_HOME}" ]; then
    _REMOTE_USER_HOME="$(getent passwd "${_REMOTE_USER}" | cut -d: -f6)"
fi

if [ -z "${_REMOTE_USER_HOME}" ]; then
    _REMOTE_USER_HOME="$([ "${_REMOTE_USER}" = "root" ] && echo /root || echo "/home/${_REMOTE_USER}")"
fi

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

echo "==> Pre-creating XDG directories for ${_REMOTE_USER} user (home: ${_REMOTE_USER_HOME})..."
mkdir -p "${_REMOTE_USER_HOME}/.config" "${_REMOTE_USER_HOME}/.local"
chown "${_REMOTE_USER}:${_REMOTE_USER}" "${_REMOTE_USER_HOME}" "${_REMOTE_USER_HOME}/.config" "${_REMOTE_USER_HOME}/.local" 2>/dev/null || true

echo "==> OpenCode feature installation complete!"
