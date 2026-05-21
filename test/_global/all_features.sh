#!/bin/bash
set -e

source dev-container-features-test-lib

check "pnpm on PATH"     bash -c "command -v pnpm"
check "claude on PATH"   bash -c "command -v claude"
check "but on PATH"      bash -c "command -v but"
check "opencode on PATH" bash -c "command -v opencode"
check "rtk on PATH"      bash -c "command -v rtk"

check "pnpm --version"     bash -c "pnpm --version"
check "claude --version"   bash -c "claude --version"
check "but --version"      bash -c "but --version"
check "opencode --version" bash -c "opencode --version"

reportResults
