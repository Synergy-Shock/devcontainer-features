#!/bin/bash
set -e
source dev-container-features-test-lib

check "whoami is node" bash -c '[ "$(whoami)" = "node" ]'
check "home writable"    bash -c 'touch "$HOME/.rwtest" && rm "$HOME/.rwtest"'
check "but on PATH"      bash -c 'command -v but'
check "but --version"    bash -c 'but --version'

check "but setup as node" bash -c '
  set -e
  # Simulate a real devcontainer where another root-running feature has already
  # created ~/.local/share, leaving it root-owned. `but setup` writes to
  # ~/.local/share/com.gitbutler.app — without the install-time pre-create, the
  # mkdir there would fail with EACCES.
  sudo mkdir -p "$HOME/.local/share"
  sudo chown root:root "$HOME/.local/share"
  mkdir -p "$HOME/proj"
  cd "$HOME/proj"
  git init -q
  git config user.email t@t
  git config user.name t
  git commit --allow-empty -qm init
  but setup
'

reportResults
