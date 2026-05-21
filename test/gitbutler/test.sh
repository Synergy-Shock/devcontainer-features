#!/bin/bash
set -e

source dev-container-features-test-lib

check "but on PATH"     bash -c "command -v but"
check "but --version"   bash -c "but --version"
check "but is executable" bash -c "test -x /usr/local/bin/but"

check "but setup" bash -c '
    set -e
    repo="$(mktemp -d)"
    cd "$repo"
    git init -q -b main
    git -c user.email=test@example.com -c user.name=test commit -q --allow-empty -m "init"
    git remote add origin "$repo"
    git update-ref refs/remotes/origin/main HEAD
    but setup
'

reportResults
