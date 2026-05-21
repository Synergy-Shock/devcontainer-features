#!/bin/bash
set -e

#-----------------------------------------------------------------------------------------------------
# OpenCode Dev Container Feature
# Installs: opencode-ai, rtk, @fission-ai/openspec
# Intended for use on Debian/Ubuntu-based images with Node.js/npm pre-installed
#-----------------------------------------------------------------------------------------------------

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

OPENCODE_VERSION="${VERSION:-latest}"
INSTALL_RTK="${INSTALLRTK:-true}"
INSTALL_OPENSPEC="${INSTALLOPENSPEC:-true}"

ARCH=$(uname -m)
case "${ARCH}" in
    x86_64)
        RTK_ARCH="x86_64"
        ;;
    aarch64|arm64)
        RTK_ARCH="aarch64"
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

echo "==> Configuring npm global prefix..."
NPM_GLOBAL_PREFIX="/usr/local/share/npm-global"
mkdir -p "${NPM_GLOBAL_PREFIX}"
npm config set prefix "${NPM_GLOBAL_PREFIX}"

export PNPM_HOME="/usr/local/share/pnpm"
mkdir -p "${PNPM_HOME}"
export PATH="${PNPM_HOME}:${PATH}"

PROFILE_SCRIPT="/etc/profile.d/opencode.sh"
cat > "${PROFILE_SCRIPT}" << EOF
export NPM_CONFIG_PREFIX=${NPM_GLOBAL_PREFIX}
export PNPM_HOME=${PNPM_HOME}
export PNPM_STORE_DIR=/usr/local/share/pnpm-store
export PATH=${NPM_GLOBAL_PREFIX}/bin:${PNPM_HOME}:/usr/local/bin:\${PATH}
EOF
chmod +x "${PROFILE_SCRIPT}"

# Ensure pnpm is available (install via npm if missing)
if ! command -v pnpm &> /dev/null; then
    echo "==> pnpm not found, installing pnpm..."
    npm install -g pnpm@10
    export SHELL=/bin/bash
    pnpm setup
fi
pnpm --version

echo "==> Configuring pnpm store directory..."
PNPM_STORE="/usr/local/share/pnpm-store"
mkdir -p "${PNPM_STORE}"
pnpm config set store-dir "${PNPM_STORE}"

# ------------------------------------------------------------------
# Install rtk (optional)
# ------------------------------------------------------------------
if [ "${INSTALL_RTK}" = "true" ]; then
    echo "==> Installing rtk..."
    RTK_LATEST=$(curl -fsSL https://api.github.com/repos/rtk-ai/rtk/releases/latest | jq -r '.tag_name')
    RTK_URL="https://github.com/rtk-ai/rtk/releases/download/${RTK_LATEST}/rtk-${RTK_ARCH}-unknown-linux-gnu.tar.gz"
    curl -fsSL "${RTK_URL}" | tar -xz -C /usr/local/bin rtk
    chmod +x /usr/local/bin/rtk
    rtk --version
else
    echo "==> Skipping rtk installation."
fi

# ------------------------------------------------------------------
# Install @fission-ai/openspec (optional)
# ------------------------------------------------------------------
if [ "${INSTALL_OPENSPEC}" = "true" ]; then
    echo "==> Installing @fission-ai/openspec..."
    pnpm install -g "@fission-ai/openspec@latest"
else
    echo "==> Skipping @fission-ai/openspec installation."
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
chown -R "${_REMOTE_USER}:${_REMOTE_USER}" /usr/local/share/pnpm /usr/local/share/npm-global /usr/local/share/pnpm-store "${OPENCODE_INSTALL_HOME}" 2>/dev/null || true

echo "==> Pre-creating XDG directories for ${_REMOTE_USER} user..."
mkdir -p "${_REMOTE_USER_HOME}/.config" "${_REMOTE_USER_HOME}/.local"
chown -R "${_REMOTE_USER}:${_REMOTE_USER}" "${_REMOTE_USER_HOME}"

echo "==> OpenCode feature installation complete!"
