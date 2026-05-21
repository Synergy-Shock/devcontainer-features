#!/bin/bash
set -e
source dev-container-features-test-lib
check "claude --version" bash -c "claude --version | grep -E '[0-9]+\\.[0-9]+\\.[0-9]+'"
reportResults
