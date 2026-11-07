#!/usr/bin/env bash
set -eu
printf '# Demo\n' > README.md
mkdir -p src
printf 'export const legacy = true;\n' > src/legacy.ts
