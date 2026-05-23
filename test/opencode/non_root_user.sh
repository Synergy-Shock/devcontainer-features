#!/bin/bash
set -e
source dev-container-features-test-lib

check "whoami is vscode"  bash -c '[ "$(whoami)" = "vscode" ]'
check "home writable"     bash -c 'touch "$HOME/.rwtest" && rm "$HOME/.rwtest"'
check "opencode on PATH"  bash -c 'command -v opencode'
check "opencode --version" bash -c 'opencode --version'
check ".config owned"     bash -c '[ "$(stat -c %U "$HOME/.config")" = "$(whoami)" ]'
check ".local owned"      bash -c '[ "$(stat -c %U "$HOME/.local")" = "$(whoami)" ]'

reportResults
