#!/usr/bin/env bash
set -eu
mkdir -p src/db
printf 'export const cleanup = "ALTER TABLE posts DROP COLUMN legacy";\n' > src/db/cleanup.ts
printf 'import { test } from "vitest";\ntest("cleanup", () => {});\n' > src/db/cleanup.test.ts
