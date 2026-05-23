#!/bin/bash
set -e

source dev-container-features-test-lib

# Proves the `node` feature (plus prerequisite `common-utils:2`) plays nicely
# alongside `claude` on a vanilla Node-less base image, without falling back
# to the `typescript-node:*` base.

check "node on PATH"     bash -c "command -v node"
check "npm on PATH"      bash -c "command -v npm"
check "pnpm on PATH"     bash -c "command -v pnpm"
check "claude on PATH"   bash -c "command -v claude"

check "node --version"   bash -c "node --version | grep -E '^v[0-9]+\\.[0-9]+\\.[0-9]+'"
check "npm --version"    bash -c "npm --version | grep -E '^[0-9]+\\.[0-9]+\\.[0-9]+'"
check "pnpm --version"   bash -c "pnpm --version | grep -E '^[0-9]+\\.[0-9]+\\.[0-9]+'"
check "claude --version" bash -c "claude --version | grep -E '[0-9]+\\.[0-9]+\\.[0-9]+'"

reportResults
