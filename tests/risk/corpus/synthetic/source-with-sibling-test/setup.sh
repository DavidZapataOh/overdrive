#!/usr/bin/env bash
set -eu
printf '# Demo\n' > README.md
mkdir -p src
printf 'export const format = (n: number) => String(n);\n' > src/format.ts
printf 'import { test } from "vitest";\ntest("format", () => {});\n' > src/format.test.ts
