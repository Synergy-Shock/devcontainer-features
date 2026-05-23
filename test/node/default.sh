#!/bin/bash
set -e
source dev-container-features-test-lib
check "node --version" bash -c "node --version | grep -E '^v[0-9]+\\.[0-9]+\\.[0-9]+'"
check "npm --version"  bash -c "npm --version | grep -E '^[0-9]+\\.[0-9]+\\.[0-9]+'"
check "pnpm --version" bash -c "pnpm --version | grep -E '^[0-9]+\\.[0-9]+\\.[0-9]+'"
reportResults
