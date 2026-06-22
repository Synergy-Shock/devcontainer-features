#!/bin/bash
set -e

#-----------------------------------------------------------------------------------------------------
# Fresh (Terminal IDE) Dev Container Feature
# Installs the `fresh` editor from the official sinelaw/fresh GitHub release
# (https://github.com/sinelaw/fresh/releases), using the static `*-unknown-linux-musl`
# prebuilt tarball so it works on any Debian/Ubuntu base regardless of glibc version.
#
# Intended for use on Debian/Ubuntu-based images that already have
# `ghcr.io/devcontainers/features/common-utils:2` applied (for curl, jq, tar, ca-certificates).
#-----------------------------------------------------------------------------------------------------

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

FRESH_VERSION="${VERSION:-latest}"

REPO_OWNER="sinelaw"
REPO_NAME="fresh"

require_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "(!) Required command '$1' is not installed."
        echo "(!) This feature assumes 'ghcr.io/devcontainers/features/common-utils:2'"
        echo "    has been added to your devcontainer.json *before* the 'fresh' feature."
        echo "    See: https://github.com/devcontainers/features/tree/main/src/common-utils"
        exit 1
    fi
}

require_cmd curl
require_cmd jq
require_cmd tar
require_cmd sha256sum

ARCH=$(uname -m)
case "${ARCH}" in
    x86_64)
        FRESH_ARCH="x86_64"
        ;;
    aarch64|arm64)
        FRESH_ARCH="aarch64"
        ;;
    *)
        echo "(!) Architecture ${ARCH} is not supported by this feature."
        exit 1
        ;;
esac

# ------------------------------------------------------------------
# Resolve the release tag.
# Asset filenames carry no version, so we only need the release tag
# for the download URL path (e.g. v0.4.1).
# A GITHUB_TOKEN in the environment, when present, lifts the anonymous
# API rate limit but is not required.
# ------------------------------------------------------------------
GH_API_AUTH=()
if [ -n "${GITHUB_TOKEN:-}" ]; then
    GH_API_AUTH=(-H "Authorization: Bearer ${GITHUB_TOKEN}")
fi

resolve_tag() {
    local req="$1"
    case "${req}" in
        latest)
            curl -fsSL "${GH_API_AUTH[@]}" \
                "https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/releases/latest" \
                | jq -r '.tag_name'
            ;;
        v[0-9]*)
            echo "${req}"
            ;;
        [0-9]*)
            echo "v${req}"
            ;;
        *)
            echo ""
            ;;
    esac
}

echo "==> Resolving Fresh version '${FRESH_VERSION}'..."
TAG=$(resolve_tag "${FRESH_VERSION}")

if [ -z "${TAG}" ] || [ "${TAG}" = "null" ]; then
    echo "(!) Could not resolve Fresh version '${FRESH_VERSION}'."
    echo "    Accepted forms: latest | <exact> (e.g. 0.4.1 or v0.4.1)"
    exit 1
fi

echo "==> Resolved Fresh ${FRESH_VERSION} -> ${TAG}"

# ------------------------------------------------------------------
# Download the static musl tarball + its .sha256, verify, then extract
# only the `fresh` binary into /usr/local/bin (already on every PATH).
# ------------------------------------------------------------------
ASSET_DIR="fresh-editor-${FRESH_ARCH}-unknown-linux-musl"
ASSET="${ASSET_DIR}.tar.gz"
BASE_URL="https://github.com/${REPO_OWNER}/${REPO_NAME}/releases/download/${TAG}"

TMP_DIR=$(mktemp -d)
cleanup() { rm -rf "${TMP_DIR}"; }
trap cleanup EXIT

echo "==> Downloading ${BASE_URL}/${ASSET}"
curl -fsSL "${BASE_URL}/${ASSET}" -o "${TMP_DIR}/${ASSET}"
curl -fsSL "${BASE_URL}/${ASSET}.sha256" -o "${TMP_DIR}/${ASSET}.sha256"

echo "==> Verifying checksum..."
EXPECTED_SHA=$(awk '{print $1}' "${TMP_DIR}/${ASSET}.sha256")
ACTUAL_SHA=$(sha256sum "${TMP_DIR}/${ASSET}" | awk '{print $1}')
if [ "${EXPECTED_SHA}" != "${ACTUAL_SHA}" ]; then
    echo "(!) Checksum mismatch for ${ASSET}."
    echo "    expected: ${EXPECTED_SHA}"
    echo "    actual:   ${ACTUAL_SHA}"
    exit 1
fi

echo "==> Installing fresh into /usr/local/bin..."
tar -xz -C /usr/local/bin --strip-components=1 --no-same-owner \
    -f "${TMP_DIR}/${ASSET}" "${ASSET_DIR}/fresh"
chmod 0755 /usr/local/bin/fresh

echo "==> Fresh feature installation complete!"
echo "    fresh: $(/usr/local/bin/fresh --version 2>/dev/null || echo "${TAG}")"
