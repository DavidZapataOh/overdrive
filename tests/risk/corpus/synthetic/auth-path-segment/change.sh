#!/usr/bin/env bash
set -eu
mkdir -p src/auth
printf 'export const login = (u: string) => u.length > 0;\n' > src/auth/login.ts
printf 'import { test } from "vitest";\ntest("login", () => {});\n' > src/auth/login.test.ts
