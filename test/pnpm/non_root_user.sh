#!/bin/bash
set -e
source dev-container-features-test-lib

check "whoami is node"  bash -c '[ "$(whoami)" = "node" ]'
check "home writable"   bash -c 'touch "$HOME/.rwtest" && rm "$HOME/.rwtest"'
check "pnpm on PATH"    bash -c 'command -v pnpm'
check "pnpm --version"  bash -c 'pnpm --version'
check "pnpm major is 11" bash -c "pnpm --version | grep -E '^11\\.'"
check "pnpm add -g without sudo" bash -c 'pnpm add -g cowsay && command -v cowsay'

reportResults
