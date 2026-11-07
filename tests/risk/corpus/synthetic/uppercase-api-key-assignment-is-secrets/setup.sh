#!/usr/bin/env bash
set -eu
printf '# Demo\n' > README.md
mkdir -p src
printf 'export const api = 1;\n' > src/client.ts
printf 'import { test } from "vitest";\ntest("x", () => {});\n' > src/client.test.ts
