#!/bin/bash
set -e
source dev-container-features-test-lib
check "claude --version reports 2.1.145" bash -c "claude --version | grep -F '2.1.145'"
reportResults
