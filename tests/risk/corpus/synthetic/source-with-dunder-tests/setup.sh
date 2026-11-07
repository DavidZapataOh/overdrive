#!/usr/bin/env bash
set -eu
printf '# Demo\n' > README.md
mkdir -p src/__tests__
printf 'export const route = "/";\n' > src/router.ts
printf 'import { test } from "vitest";\ntest("route", () => {});\n' > src/__tests__/router.ts
