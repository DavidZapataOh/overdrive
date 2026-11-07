#!/usr/bin/env bash
set -eu
printf '# Demo\n' > README.md
mkdir -p src/ledger
printf 'export const begin = "BEGIN";\n' > src/ledger/tx.ts
printf 'import { test } from "vitest";\ntest("begin", () => {});\n' > src/ledger/tx.test.ts
