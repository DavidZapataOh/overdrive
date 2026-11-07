#!/usr/bin/env bash
set -eu
printf 'export const format = (n: number) => n.toFixed(2);\n' > src/format.ts
