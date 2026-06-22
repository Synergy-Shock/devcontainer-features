#!/bin/bash
set -e
source dev-container-features-test-lib
check "fresh 0.4.1" bash -c "fresh --version | grep -F '0.4.1'"
reportResults
