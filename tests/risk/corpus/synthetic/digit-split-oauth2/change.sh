#!/usr/bin/env bash
set -eu
mkdir -p src/oauth2
printf 'export const x = 1;\n' > src/oauth2/cb.ts
printf 'import { test } from "vitest";\ntest("x", () => {});\n' > src/oauth2/cb.test.ts
