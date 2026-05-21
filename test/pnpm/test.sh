#!/bin/bash
set -e

source dev-container-features-test-lib

check "pnpm on PATH"           bash -c "command -v pnpm"
check "pnpm --version"         bash -c "pnpm --version | grep -E '[0-9]+\\.[0-9]+\\.[0-9]+'"
check "store dir configured"   bash -c "test -d /usr/local/share/pnpm-store"
check "npm prefix configured"  bash -c "test -d /usr/local/share/npm-global"
check "profile.d snippet"      bash -c "test -x /etc/profile.d/pnpm.sh"

reportResults
