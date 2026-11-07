#!/usr/bin/env bash
set -eu
printf '# Demo\n' > README.md
mkdir -p config
printf 'name: web\n' > config/app.yml
