#!/usr/bin/env bash
set -eu
mkdir -p src/store
printf 'export const x = 1;\n' > src/store/userSessions.ts
printf 'import { test } from "vitest";\ntest("x", () => {});\n' > src/store/userSessions.test.ts
