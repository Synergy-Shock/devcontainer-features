#!/bin/bash
set -e
source dev-container-features-test-lib

check "whoami is vscode" bash -c '[ "$(whoami)" = "vscode" ]'
check "home writable"    bash -c 'touch "$HOME/.rwtest" && rm "$HOME/.rwtest"'
check "rtk on PATH"      bash -c 'command -v rtk'
check "rtk --version"    bash -c 'rtk --version'

reportResults
