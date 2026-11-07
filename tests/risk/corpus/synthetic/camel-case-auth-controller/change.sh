#!/usr/bin/env bash
set -eu
mkdir -p src/controllers
printf 'export const x = 1;\n' > src/controllers/AuthController.ts
printf 'import { test } from "vitest";\ntest("x", () => {});\n' > src/controllers/AuthController.test.ts
