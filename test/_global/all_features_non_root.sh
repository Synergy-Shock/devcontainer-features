#!/bin/bash
set -e
source dev-container-features-test-lib

check "whoami is node" bash -c '[ "$(whoami)" = "node" ]'
check "home writable"  bash -c 'touch "$HOME/.rwtest" && rm "$HOME/.rwtest"'

check "claude on PATH"   bash -c "command -v claude"
check "but on PATH"      bash -c "command -v but"
check "opencode on PATH" bash -c "command -v opencode"
check "rtk on PATH"      bash -c "command -v rtk"

check "claude --version"   bash -c "claude --version"
check "but --version"      bash -c "but --version"
check "opencode --version" bash -c "opencode --version"
check "rtk --version"      bash -c "rtk --version"

reportResults
