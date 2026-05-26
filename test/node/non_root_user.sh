#!/bin/bash
set -e
source dev-container-features-test-lib
check "node --version as non-root" bash -c "node --version | grep -E '^v[0-9]+\\.[0-9]+\\.[0-9]+'"
check "pnpm --version as non-root" bash -c "pnpm --version | grep -E '^[0-9]+\\.[0-9]+\\.[0-9]+'"
check "running as non-root"        bash -c "test \"$(id -un)\" = 'vscode'"

# Regression: pnpm v10.18+ opens a SQLite store index (WAL mode). A previous
# version of this feature left /usr/local/share/{npm-global,pnpm} root-owned,
# causing "ERR_SQLITE_ERROR: attempt to write a readonly database" on the
# first non-root `pnpm install`. `pnpm --version` does not exercise the store.
check "pnpm install as non-root" bash -c '
  set -e
  d=$(mktemp -d)
  cd "$d"
  cat > package.json <<JSON
{ "name": "t", "version": "0.0.0", "dependencies": { "is-odd": "3.0.1" } }
JSON
  pnpm config set store-dir "$d/.pnpm-store"
  pnpm install --no-frozen-lockfile --ignore-scripts
  test -d "$d/node_modules/is-odd"
'

reportResults
