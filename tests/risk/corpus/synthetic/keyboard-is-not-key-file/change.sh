#!/usr/bin/env bash
set -eu
mkdir -p src
printf 'export const layout = "qwerty";\n' > src/keyboard.ts
printf 'import { test } from "vitest";\ntest("layout", () => {});\n' > src/keyboard.test.ts
