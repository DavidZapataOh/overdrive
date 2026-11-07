#!/usr/bin/env bash
set -eu
mkdir -p src
printf 'export const pkg = "demo";\n' > src/package.ts
printf 'import { test } from "vitest";\ntest("pkg", () => {});\n' > src/package.test.ts
