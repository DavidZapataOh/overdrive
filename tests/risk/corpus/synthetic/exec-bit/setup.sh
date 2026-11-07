#!/usr/bin/env bash
set -eu
printf '# Demo\n' > README.md
mkdir -p scripts
printf 'echo build\n' > scripts/build.sh
