#!/usr/bin/env bash
set -eu
printf '# Demo\n' > README.md
mkdir -p .github/workflows
printf 'name: ci\non: push\n' > .github/workflows/ci.yml
