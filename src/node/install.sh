#!/bin/bash
set -e

#-----------------------------------------------------------------------------------------------------
# Node.js Dev Container Feature
# Installs the official Node.js prebuilt binary from https://nodejs.org/dist/, then pins npm
# (via `npm install -g`) and pnpm (via the official GitHub-release binary from pnpm/pnpm).
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
        PNPM_ARCH="x64"
        ;;
    aarch64|arm64)
        NODE_ARCH="arm64"
        PNPM_ARCH="arm64"
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
# Pin / update npm
# ------------------------------------------------------------------
echo "==> Installing npm@${NPM_VERSION_OPT}..."
npm install -g --no-fund --no-audit "npm@${NPM_VERSION_OPT}"
npm --version

# ------------------------------------------------------------------
# Install pnpm directly from the official GitHub release binary
# (https://pnpm.io/installation – the standalone binary path)
# ------------------------------------------------------------------
echo "==> Resolving pnpm version '${PNPM_VERSION_OPT}'..."
if [ "${PNPM_VERSION_OPT}" = "latest" ]; then
    PNPM_TAG=$(curl -fsSL https://api.github.com/repos/pnpm/pnpm/releases/latest | jq -r '.tag_name')
    if [ -z "${PNPM_TAG}" ] || [ "${PNPM_TAG}" = "null" ]; then
        echo "(!) Failed to resolve latest pnpm release from api.github.com/repos/pnpm/pnpm/releases/latest"
        exit 1
    fi
else
    case "${PNPM_VERSION_OPT}" in
        v*) PNPM_TAG="${PNPM_VERSION_OPT}" ;;
        *)  PNPM_TAG="v${PNPM_VERSION_OPT}" ;;
    esac
fi

PNPM_URL="https://github.com/pnpm/pnpm/releases/download/${PNPM_TAG}/pnpm-linux-${PNPM_ARCH}.tar.gz"
echo "==> Downloading ${PNPM_URL}"
# The tarball ships a self-contained `pnpm` ELF at its top level alongside a
# `dist/` directory of auxiliary node-script form; we only need the binary.
curl -fsSL "${PNPM_URL}" | tar -xz -C /usr/local/bin --no-same-owner pnpm
chmod +x /usr/local/bin/pnpm
pnpm --version

echo "==> Node feature installation complete!"
echo "    node:  $(node --version)"
echo "    npm:   $(npm --version)"
echo "    pnpm:  $(pnpm --version)"
