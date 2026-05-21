#!/bin/bash
set -e
source dev-container-features-test-lib
check "pnpm major is 9" bash -c "pnpm --version | grep -E '^9\\.'"
reportResults
