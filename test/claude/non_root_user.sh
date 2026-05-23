#!/bin/bash
set -e
source dev-container-features-test-lib

check "whoami is vscode"   bash -c '[ "$(whoami)" = "vscode" ]'
check "home writable"      bash -c 'touch "$HOME/.rwtest" && rm "$HOME/.rwtest"'
check "claude on PATH"     bash -c 'command -v claude'
check "claude --version"   bash -c "claude --version | grep -E '[0-9]+\\.[0-9]+\\.[0-9]+'"
check "claude dir readable" test -r /usr/local/share/claude

reportResults
