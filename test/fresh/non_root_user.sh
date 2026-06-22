#!/bin/bash
set -e
source dev-container-features-test-lib
check "running as non-root"          bash -c "test \"$(id -un)\" = 'vscode'"
check "fresh on PATH as non-root"    bash -c "command -v fresh"
check "fresh --version as non-root"  bash -c "fresh --version | grep -E '[0-9]+\\.[0-9]+\\.[0-9]+'"
reportResults
