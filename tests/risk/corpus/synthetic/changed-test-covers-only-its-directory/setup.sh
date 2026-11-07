#!/usr/bin/env bash
set -eu
printf '# Demo\n' > README.md
mkdir -p src/a src/b
printf 'export const x = 1;\n' > src/a/x.ts
printf 'export const y = 1;\n' > src/b/y.ts
