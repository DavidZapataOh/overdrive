#!/usr/bin/env bash
set -eu
printf '# Demo\n' > README.md
mkdir -p src/orders
printf 'export const list = (db: any) => db.select("orders");\n' > src/orders/query.ts
printf 'import { test } from "vitest";\ntest("list", () => {});\n' > src/orders/query.test.ts
