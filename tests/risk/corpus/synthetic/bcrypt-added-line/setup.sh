#!/usr/bin/env bash
set -eu
printf '# Demo\n' > README.md
mkdir -p src/users
printf 'export const hash = (s: string) => s;\n' > src/users/hash.ts
printf 'import { test } from "vitest";\ntest("hash", () => {});\n' > src/users/hash.test.ts
