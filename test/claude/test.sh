#!/bin/bash
set -e

source dev-container-features-test-lib

check "claude on PATH"      bash -c "command -v claude"
check "claude --version"    bash -c "claude --version | grep -E '[0-9]+\\.[0-9]+\\.[0-9]+'"
check "launcher symlinked"  bash -c "test -L /usr/local/bin/claude"

reportResults
