#!/bin/bash
set -e
source dev-container-features-test-lib
check "opencode --version" bash -c "opencode --version"
check "rtk NOT installed"  bash -c "! command -v rtk"
reportResults
