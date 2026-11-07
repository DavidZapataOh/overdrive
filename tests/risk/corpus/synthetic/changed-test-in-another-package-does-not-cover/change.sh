#!/usr/bin/env bash
set -eu
printf 'export const f = 2;\n' > packages/a/src/format.ts
printf 'import { test } from "vitest";\ntest("x", () => {});\n' > packages/b/test/format.test.ts
