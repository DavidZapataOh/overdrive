#!/usr/bin/env bash
set -eu
printf '# Demo\n' > README.md
mkdir -p src/b
printf 'export const y = 1;\n' > src/b/y.ts
