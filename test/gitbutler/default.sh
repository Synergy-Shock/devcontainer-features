#!/bin/bash
set -e
source dev-container-features-test-lib
check "but --version" bash -c "but --version"
reportResults
