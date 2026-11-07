#!/usr/bin/env bash
set -eu
mkdir -p src/store
printf 'export const x = 1;\n' > src/store/sessionStore.ts
printf 'import { test } from "vitest";\ntest("x", () => {});\n' > src/store/sessionStore.test.ts
