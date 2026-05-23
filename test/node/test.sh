#!/bin/bash
set -e

source dev-container-features-test-lib

check "node on PATH"     bash -c "command -v node"
check "node --version"   bash -c "node --version | grep -E '^v[0-9]+\\.[0-9]+\\.[0-9]+'"
check "npm on PATH"      bash -c "command -v npm"
check "npm --version"    bash -c "npm --version | grep -E '^[0-9]+\\.[0-9]+\\.[0-9]+'"
check "pnpm on PATH"     bash -c "command -v pnpm"
check "pnpm --version"   bash -c "pnpm --version | grep -E '^[0-9]+\\.[0-9]+\\.[0-9]+'"
check "node at /usr/local/bin/node"  bash -c "test -x /usr/local/bin/node"
check "pnpm at /usr/local/bin/pnpm"  bash -c "test -x /usr/local/bin/pnpm"
check "no /usr/local/CHANGELOG.md"   bash -c "test ! -e /usr/local/CHANGELOG.md"

reportResults
