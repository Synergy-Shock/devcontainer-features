#!/bin/bash
set -e
source dev-container-features-test-lib
check "pnpm major is 10" bash -c "pnpm --version | grep -E '^10\\.'"
reportResults
