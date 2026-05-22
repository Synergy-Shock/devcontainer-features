#!/bin/bash
set -e
source dev-container-features-test-lib

check "whoami is node"     bash -c '[ "$(whoami)" = "node" ]'
check "home writable"      bash -c 'touch "$HOME/.rwtest" && rm "$HOME/.rwtest"'
check "but on PATH"        bash -c 'command -v but'
check "opencode on PATH"   bash -c 'command -v opencode'

check "but setup as node with opencode installed" bash -c '
  set -e
  mkdir -p "$HOME/proj"
  cd "$HOME/proj"
  git init -q
  git config user.email t@t
  git config user.name t
  git commit --allow-empty -qm init
  but setup
'

reportResults
