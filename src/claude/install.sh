#!/bin/bash
set -e

#-----------------------------------------------------------------------------------------------------
# Claude Code Dev Container Feature
# Installs the Claude Code CLI via the official installer: https://claude.ai/install.sh
# Intended for use on Debian/Ubuntu-based images.
#-----------------------------------------------------------------------------------------------------

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

CLAUDE_VERSION="${VERSION:-latest}"

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y --no-install-recommends curl ca-certificates git
rm -rf /var/lib/apt/lists/*

# Install into a system-wide HOME so we do not write into /home/node/.claude, which
# is bind-mounted from the host at runtime and would shadow anything we put there.
CLAUDE_INSTALL_HOME="/usr/local/share/claude"
mkdir -p "${CLAUDE_INSTALL_HOME}"

INSTALL_ARG=""
if [ "${CLAUDE_VERSION}" != "latest" ]; then
    INSTALL_ARG="${CLAUDE_VERSION}"
fi

echo "==> Installing Claude Code (${CLAUDE_VERSION}) via https://claude.ai/install.sh ..."
HOME="${CLAUDE_INSTALL_HOME}" bash -c "curl -fsSL https://claude.ai/install.sh | bash -s -- ${INSTALL_ARG}"

# Expose the launcher on PATH for every user without depending on shell rc files.
ln -sf "${CLAUDE_INSTALL_HOME}/.local/bin/claude" /usr/local/bin/claude

claude --version

chown -R "${_REMOTE_USER}:${_REMOTE_USER}" "${CLAUDE_INSTALL_HOME}"

echo "==> Claude Code feature installation complete!"
