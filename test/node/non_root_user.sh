#!/bin/bash
set -e
source dev-container-features-test-lib
check "node --version as non-root" bash -c "node --version | grep -E '^v[0-9]+\\.[0-9]+\\.[0-9]+'"
check "pnpm --version as non-root" bash -c "pnpm --version | grep -E '^[0-9]+\\.[0-9]+\\.[0-9]+'"
check "running as non-root"        bash -c "test \"$(id -un)\" = 'vscode'"
reportResults
