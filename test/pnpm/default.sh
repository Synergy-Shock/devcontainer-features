#!/bin/bash
set -e
source dev-container-features-test-lib
check "pnpm major is 11" bash -c "pnpm --version | grep -E '^11\\.'"
reportResults
