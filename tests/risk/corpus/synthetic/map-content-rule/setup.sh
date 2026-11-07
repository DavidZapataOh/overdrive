#!/usr/bin/env bash
set -eu
printf '# Demo\n' > README.md
mkdir -p src/orders
printf 'export const place = async (db: any) => db;\n' > src/orders/place.ts
printf 'import { test } from "vitest";\ntest("place", () => {});\n' > src/orders/place.test.ts
