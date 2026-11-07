#!/usr/bin/env bash
set -eu
mkdir -p src/authentication
printf 'export const x = 1;\n' > src/authentication/a.ts
printf 'import { test } from "vitest";\ntest("x", () => {});\n' > src/authentication/a.test.ts
mkdir -p src/authorization
printf 'export const x = 1;\n' > src/authorization/b.ts
printf 'import { test } from "vitest";\ntest("x", () => {});\n' > src/authorization/b.test.ts
