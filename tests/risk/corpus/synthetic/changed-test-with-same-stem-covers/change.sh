#!/usr/bin/env bash
set -eu
mkdir -p e2e
printf 'export const y = 2;\n' > src/b/y.ts
printf 'import { test } from "vitest";\ntest("x", () => {});\n' > e2e/y.spec.ts
