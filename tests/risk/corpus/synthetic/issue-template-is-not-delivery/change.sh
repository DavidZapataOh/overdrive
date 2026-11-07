#!/usr/bin/env bash
set -eu
mkdir -p .github/ISSUE_TEMPLATE
printf -- '---\nname: Bug\n---\n' > .github/ISSUE_TEMPLATE/bug.md
