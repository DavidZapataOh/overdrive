#!/usr/bin/env bash
set -eu
mkdir -p src/Auth
printf 'export const check = () => true;\n' > src/Auth/Check.ts
printf 'import { test } from "vitest";\ntest("check", () => {});\n' > src/Auth/Check.test.ts
