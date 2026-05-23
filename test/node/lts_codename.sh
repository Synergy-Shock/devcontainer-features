#!/bin/bash
set -e
source dev-container-features-test-lib
check "lts/krypton resolves to v24.x" bash -c "node --version | grep -E '^v24\\.[0-9]+\\.[0-9]+'"
reportResults
