#!/bin/bash
set -e
source dev-container-features-test-lib
check "fresh on PATH"   bash -c "command -v fresh"
check "fresh --version" bash -c "fresh --version | grep -E '[0-9]+\\.[0-9]+\\.[0-9]+'"
reportResults
