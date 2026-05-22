#!/bin/bash
set -e

#-----------------------------------------------------------------------------------------------------
# pnpm Dev Container Feature
# Installs: pnpm, configures npm global prefix and pnpm store directory
# Intended for use on Debian/Ubuntu-based images with Node.js/npm pre-installed
#-----------------------------------------------------------------------------------------------------

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

PNPM_VERSION="${VERSION:-11}"

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y --no-install-recommends curl
rm -rf /var/lib/apt/lists/*

echo "==> Configuring npm global prefix..."
NPM_GLOBAL_PREFIX="/usr/local/share/npm-global"
mkdir -p "${NPM_GLOBAL_PREFIX}"
npm config set prefix "${NPM_GLOBAL_PREFIX}"

export PNPM_HOME="/usr/local/share/pnpm"
mkdir -p "${PNPM_HOME}/bin"
export PATH="${PNPM_HOME}:${PATH}"

PROFILE_SCRIPT="/etc/profile.d/pnpm.sh"
cat > "${PROFILE_SCRIPT}" << EOF
export NPM_CONFIG_PREFIX=${NPM_GLOBAL_PREFIX}
export PNPM_HOME=${PNPM_HOME}
export PNPM_STORE_DIR=/usr/local/share/pnpm-store
export PATH=${NPM_GLOBAL_PREFIX}/bin:${PNPM_HOME}:${PNPM_HOME}/bin:/usr/local/bin:\${PATH}
EOF
chmod +x "${PROFILE_SCRIPT}"

echo "==> Installing pnpm@${PNPM_VERSION}..."
npm install -g "pnpm@${PNPM_VERSION}"
export SHELL=/bin/bash
pnpm setup
pnpm --version

echo "==> Configuring pnpm store directory..."
PNPM_STORE="/usr/local/share/pnpm-store"
mkdir -p "${PNPM_STORE}"
pnpm config set store-dir "${PNPM_STORE}"

REMOTE_USER="${_REMOTE_USER:-root}"
echo "==> Adjusting permissions for ${REMOTE_USER} user..."
chown -R "${REMOTE_USER}:${REMOTE_USER}" \
    /usr/local/share/pnpm \
    /usr/local/share/npm-global \
    /usr/local/share/pnpm-store

echo "==> pnpm feature installation complete!"
