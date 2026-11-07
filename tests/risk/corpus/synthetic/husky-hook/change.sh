#!/usr/bin/env bash
set -eu
mkdir -p .husky
printf 'npm test\n' > .husky/pre-commit
