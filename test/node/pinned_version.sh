#!/bin/bash
set -e
source dev-container-features-test-lib
check "node v24.16.0"   bash -c "node --version | grep -F 'v24.16.0'"
check "npm 11.15.0"     bash -c "npm --version | grep -F '11.15.0'"
check "pnpm 11.2.2"     bash -c "pnpm --version | grep -F '11.2.2'"
reportResults
