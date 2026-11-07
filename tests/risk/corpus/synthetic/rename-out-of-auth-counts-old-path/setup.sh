#!/usr/bin/env bash
set -eu
printf '# Demo\n' > README.md
mkdir -p src/auth
printf 'export const x = 1;\n' > src/auth/x.ts
printf 'import { test } from "vitest";\ntest("x", () => {});\n' > src/auth/x.test.ts
