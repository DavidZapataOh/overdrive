#!/usr/bin/env bash
set -eu
printf '# Demo\n' > README.md
mkdir -p src/api
printf 'export const users = () => [];\n' > src/api/users.ts
printf 'import { test } from "vitest";\ntest("users", () => {});\n' > src/api/users.test.ts
