#!/bin/bash
set -e

source dev-container-features-test-lib

check "opencode on PATH"   bash -c "command -v opencode"
check "opencode --version" bash -c "opencode --version"

reportResults
