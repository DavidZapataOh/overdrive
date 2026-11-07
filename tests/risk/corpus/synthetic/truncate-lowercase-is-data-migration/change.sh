#!/usr/bin/env bash
set -eu
mkdir -p src/db
printf 'export const reset = "truncate users;";\n' > src/db/reset.ts
printf 'import { test } from "vitest";\ntest("reset", () => {});\n' > src/db/reset.test.ts
