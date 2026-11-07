#!/usr/bin/env bash
set -eu
printf '# Demo\n' > README.md
mkdir -p .github/workflows
printf '{ "name": "demo", "version": "1.0.0" }\n' > package.json
printf 'name: ci\non: push\n' > .github/workflows/ci.yml
