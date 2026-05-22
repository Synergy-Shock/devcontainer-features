#!/bin/bash
set -e
source dev-container-features-test-lib
check "rtk --version" bash -c "rtk --version"
reportResults
