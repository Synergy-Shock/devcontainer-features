#!/bin/bash
set -e

source dev-container-features-test-lib

check "fresh on PATH"               bash -c "command -v fresh"
check "fresh at /usr/local/bin"     bash -c "test -x /usr/local/bin/fresh"
check "fresh --version"             bash -c "fresh --version | grep -E '[0-9]+\\.[0-9]+\\.[0-9]+'"
check "no tarball leftovers in bin" bash -c "test ! -e /usr/local/bin/LICENSE -a ! -d /usr/local/bin/icons"

reportResults
