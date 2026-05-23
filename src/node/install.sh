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
# Pin / update npm
# ------------------------------------------------------------------
echo "==> Installing npm@${NPM_VERSION_OPT}..."
npm install -g --no-fund --no-audit "npm@${NPM_VERSION_OPT}"
npm --version

# ------------------------------------------------------------------
# Install pnpm via the official install script
# (https://pnpm.io/installation – the get.pnpm.io/install.sh path)
# ------------------------------------------------------------------
echo "==> Installing pnpm@${PNPM_VERSION_OPT} via get.pnpm.io/install.sh..."

export PNPM_HOME="/usr/local/share/pnpm"
mkdir -p "${PNPM_HOME}"

# The install script reads PNPM_VERSION (optional) and PNPM_HOME (install
# target), and consults $SHELL to decide which profile to touch. Set SHELL
# explicitly so it doesn't bail with "Could not infer shell" under the
# non-interactive feature build.
if [ "${PNPM_VERSION_OPT}" = "latest" ]; then
    curl -fsSL https://get.pnpm.io/install.sh \
        | env PNPM_HOME="${PNPM_HOME}" SHELL="/bin/bash" sh -
else
    # Accept both '10.0.0' and 'v10.0.0' — the install script wants no leading 'v'.
    PNPM_VER="${PNPM_VERSION_OPT#v}"
    curl -fsSL https://get.pnpm.io/install.sh \
        | env PNPM_VERSION="${PNPM_VER}" PNPM_HOME="${PNPM_HOME}" SHELL="/bin/bash" sh -
fi

# Locate the pnpm binary the install script wrote. pnpm v11+ uses
# $PNPM_HOME/bin/pnpm; older versions wrote it directly to $PNPM_HOME/pnpm.
if [ -x "${PNPM_HOME}/bin/pnpm" ]; then
    PNPM_BIN="${PNPM_HOME}/bin/pnpm"
elif [ -x "${PNPM_HOME}/pnpm" ]; then
    PNPM_BIN="${PNPM_HOME}/pnpm"
else
    echo "(!) pnpm install did not produce a binary under ${PNPM_HOME}."
    ls -la "${PNPM_HOME}" || true
    exit 1
fi

# Symlink into a directory already on every shell's PATH so the binary is
# reachable without sourcing the rc-file shim the install script writes.
ln -sf "${PNPM_BIN}" /usr/local/bin/pnpm

pnpm --version

echo "==> Node feature installation complete!"
echo "    node:  $(node --version)"
echo "    npm:   $(npm --version)"
echo "    pnpm:  $(pnpm --version)"
