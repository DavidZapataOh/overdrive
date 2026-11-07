#!/usr/bin/env bash
set -eu
printf '# Demo\n' > README.md
mkdir -p src/conf
printf 'export const users = {};\n' > src/conf/users.ts
printf 'import { test } from "vitest";\ntest("x", () => {});\n' > src/conf/users.test.ts
