#!/usr/bin/env bash
set -eu
mkdir -p src
printf 'export const ttl = 3600;\n' > src/user_session.ts
printf 'import { test } from "vitest";\ntest("ttl", () => {});\n' > src/user_session.test.ts
