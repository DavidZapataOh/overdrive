#!/usr/bin/env bash
set -eu
printf '# Demo\n' > README.md
mkdir -p src
printf 'export const fee = 0;\n' > src/fees.ts
printf 'import { test } from "vitest";\ntest("fee", () => {});\n' > src/fees.test.ts
