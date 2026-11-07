#!/usr/bin/env bash
set -eu
printf '# Demo\n' > README.md
mkdir -p e2e
printf 'export default {};\n' > playwright.config.ts
