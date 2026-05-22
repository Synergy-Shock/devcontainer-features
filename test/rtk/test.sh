#!/bin/bash
set -e

source dev-container-features-test-lib

check "rtk on PATH"   bash -c "command -v rtk"
check "rtk --version" bash -c "rtk --version"

reportResults
