#!/usr/bin/env bash
set -eu
printf '# Demo\n' > README.md
mkdir -p src
printf 'export const a = 1;\n' > src/a.ts
printf 'export const b = 1;\n' > src/b.ts
