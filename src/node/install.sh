#!/bin/bash
set -e

#-----------------------------------------------------------------------------------------------------
# Node.js Dev Container Feature
# Installs the official Node.js prebuilt binary from https://nodejs.org/dist/, then pins npm
# (via `npm install -g`) and pnpm (via the official install script at https://get.pnpm.io/install.sh).
#
# Intended for use on Debian/Ubuntu-based images that already have
# `ghcr.io/devcontainers/features/common-utils:2` applied (for curl, jq, tar, ca-certificates).
#-----------------------------------------------------------------------------------------------------

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

NODE_VERSION="${VERSION:-lts}"
NPM_VERSION_OPT="${NPMVERSION:-latest}"
PNPM_VERSION_OPT="${PNPMVERSION:-latest}"

require_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "(!) Required command '$1' is not installed."
        echo "(!) This feature assumes 'ghcr.io/devcontainers/features/common-utils:2'"
        echo "    has been added to your devcontainer.json *before* the 'node' feature."
        echo "    See: https://github.com/devcontainers/features/tree/main/src/common-utils"
        exit 1
    fi
}

require_cmd curl
require_cmd jq
require_cmd tar

ARCH=$(uname -m)
case "${ARCH}" in
    x86_64)
        NODE_ARCH="x64"
        ;;
    aarch64|arm64)
        NODE_ARCH="arm64"
        ;;
    *)
        echo "(!) Architecture ${ARCH} is not supported by this feature."
        exit 1
        ;;
esac

# ------------------------------------------------------------------
# Resolve Node version against the official nodejs.org index
# ------------------------------------------------------------------
NODE_INDEX_URL="https://nodejs.org/dist/index.json"

resolve_node_version() {
    local req="$1"
    local index="$2"

    case "${req}" in
        lts)
            echo "${index}" | jq -r '[.[] | select(.lts != false)][0].version'
            ;;
        latest|current)
            echo "${index}" | jq -r '.[0].version'
            ;;
        lts/*)
            local codename="${req#lts/}"
            echo "${index}" | jq -r --arg c "${codename}" '
                [.[] | select((.lts | type) == "string" and (.lts | ascii_downcase) == ($c | ascii_downcase))][0].version'
            ;;
        v[0-9]*.[0-9]*.[0-9]*)
            echo "${req}"
            ;;
        [0-9]*.[0-9]*.[0-9]*)
            echo "v${req}"
            ;;
        v[0-9]*.[0-9]*)
            echo "${index}" | jq -r --arg p "${req}." '[.[] | select(.version | startswith($p))][0].version'
            ;;
        [0-9]*.[0-9]*)
            echo "${index}" | jq -r --arg p "v${req}." '[.[] | select(.version | startswith($p))][0].version'
            ;;
        v[0-9]*)
            echo "${index}" | jq -r --arg p "${req}." '[.[] | select(.version | startswith($p))][0].version'
            ;;
        [0-9]*)
            echo "${index}" | jq -r --arg p "v${req}." '[.[] | select(.version | startswith($p))][0].version'
            ;;
        *)
            echo ""
            ;;
    esac
}

echo "==> Resolving Node version '${NODE_VERSION}'..."
NODE_INDEX=$(curl -fsSL "${NODE_INDEX_URL}")
RESOLVED_VERSION=$(resolve_node_version "${NODE_VERSION}" "${NODE_INDEX}")

if [ -z "${RESOLVED_VERSION}" ] || [ "${RESOLVED_VERSION}" = "null" ]; then
    echo "(!) Could not resolve Node version '${NODE_VERSION}' from ${NODE_INDEX_URL}."
    echo "    Accepted forms: lts | latest | lts/<codename> | <major> | <major>.<minor> | <exact>"
    exit 1
fi

echo "==> Resolved Node ${NODE_VERSION} -> ${RESOLVED_VERSION}"

# ------------------------------------------------------------------
# Download & extract Node into /usr/local (FHS merge)
# ------------------------------------------------------------------
NODE_TARBALL="node-${RESOLVED_VERSION}-linux-${NODE_ARCH}.tar.gz"
NODE_URL="https://nodejs.org/dist/${RESOLVED_VERSION}/${NODE_TARBALL}"

echo "==> Downloading ${NODE_URL}"
curl -fsSL "${NODE_URL}" \
    | tar -xz -C /usr/local --strip-components=1 --no-same-owner \
          --exclude='CHANGELOG.md' \
          --exclude='LICENSE' \
          --exclude='README.md'

node --version
npm --version

# ------------------------------------------------------------------
# Pin / update npm — installs into the Node tarball's prefix (/usr/local),
# overwriting /usr/local/bin/npm.
# ------------------------------------------------------------------
echo "==> Installing npm@${NPM_VERSION_OPT}..."
npm install -g --no-fund --no-audit "npm@${NPM_VERSION_OPT}"
npm --version

# ------------------------------------------------------------------
# Install pnpm via npm. From here on, npm globals live in a dedicated
# directory exposed on PATH via /etc/profile.d/node.sh, keeping
# user-installed globals separate from the Node tarball's /usr/local/bin.
#
# When a non-root remote user is configured, the dirs live under their HOME
# (XDG-style) so non-root `pnpm install` can write the SQLite store index
# (WAL files) without "readonly database". Otherwise they land system-wide
# under /usr/local/share.
# ------------------------------------------------------------------
if [ -n "${_REMOTE_USER:-}" ] && [ "${_REMOTE_USER}" != "root" ]; then
    REMOTE_USER_HOME="${_REMOTE_USER_HOME:-/home/${_REMOTE_USER}}"
    NPM_CONFIG_PREFIX="${REMOTE_USER_HOME}/.local/share/npm-global"
    PNPM_HOME="${REMOTE_USER_HOME}/.local/share/pnpm"
else
    NPM_CONFIG_PREFIX="/usr/local/share/npm-global"
    PNPM_HOME="/usr/local/share/pnpm"
fi
export NPM_CONFIG_PREFIX PNPM_HOME
mkdir -p "${NPM_CONFIG_PREFIX}/bin" "${PNPM_HOME}"

echo "==> Installing pnpm@${PNPM_VERSION_OPT} via npm into ${NPM_CONFIG_PREFIX}..."
# Accept both '10.0.0' and 'v10.0.0' — npm semver wants no leading 'v'.
PNPM_SPEC="${PNPM_VERSION_OPT#v}"
npm install -g --no-fund --no-audit "pnpm@${PNPM_SPEC}"

# Symlink pnpm into /usr/local/bin so it is reachable from any shell even
# before /etc/profile.d/node.sh is sourced (matches npm's own /usr/local/bin/npm
# symlink that the Node tarball ships).
ln -sf "${NPM_CONFIG_PREFIX}/bin/pnpm" /usr/local/bin/pnpm

# Make pnpm reachable for the verification call below; persisted to future
# shells via /etc/profile.d/node.sh, written next.
export PATH="${NPM_CONFIG_PREFIX}/bin:${PNPM_HOME}:${PATH}"
pnpm --version

# Hand the global npm/pnpm trees to the remote user so non-root pnpm operations
# can write SQLite state (store index, WAL files) without "readonly database".
if [ -n "${_REMOTE_USER:-}" ] && [ "${_REMOTE_USER}" != "root" ]; then
    chown -R "${_REMOTE_USER}:${_REMOTE_USER}" "${NPM_CONFIG_PREFIX}" "${PNPM_HOME}"
fi

# ------------------------------------------------------------------
# Persist env vars and PATH additions for future shells.
# /etc/profile is sourced by login shells; common-utils:2 (a prerequisite)
# also wires /etc/bash.bashrc to source /etc/profile.d/*.sh.
# ------------------------------------------------------------------
cat > /etc/profile.d/node.sh <<EOF
export NPM_CONFIG_PREFIX="${NPM_CONFIG_PREFIX}"
export PNPM_HOME="${PNPM_HOME}"
export PATH="\${NPM_CONFIG_PREFIX}/bin:\${PNPM_HOME}:\${PATH}"
EOF
chmod 0644 /etc/profile.d/node.sh

echo "==> Node feature installation complete!"
echo "    node:  $(node --version)"
echo "    npm:   $(npm --version)"
echo "    pnpm:  $(pnpm --version)"
