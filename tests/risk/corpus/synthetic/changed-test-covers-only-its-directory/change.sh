#!/usr/bin/env bash
set -eu
printf 'export const x = 2;\n' > src/a/x.ts
printf 'export const y = 2;\n' > src/b/y.ts
printf 'import { test } from "vitest";\ntest("x", () => {});\n' > src/a/helpers.test.ts
