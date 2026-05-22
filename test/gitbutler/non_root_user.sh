#!/bin/bash
set -e
source dev-container-features-test-lib

check "whoami is vscode" bash -c '[ "$(whoami)" = "vscode" ]'
check "home writable"    bash -c 'touch "$HOME/.rwtest" && rm "$HOME/.rwtest"'
check "but on PATH"      bash -c 'command -v but'
check "but --version"    bash -c 'but --version'

check "but setup as vscode" bash -c '
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
