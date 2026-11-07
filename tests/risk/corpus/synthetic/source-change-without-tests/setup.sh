#!/usr/bin/env bash
set -eu
printf '# Demo\n' > README.md
mkdir -p src
printf 'export const format = (n: number) => String(n);\n' > src/format.ts
