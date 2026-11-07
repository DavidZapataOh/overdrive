#!/usr/bin/env bash
set -eu
printf '# Demo\n' > README.md
mkdir -p src/repo
printf 'export const find = (db, tenantId) => db.where({ tenantId });\n' > src/repo/orders.ts
printf 'import { test } from "vitest";\ntest("x", () => {});\n' > src/repo/orders.test.ts
