#!/usr/bin/env bash
set -eu
mkdir -p src/lib
printf 'export const x = 1;\n' > src/lib/OAuthToken.ts
printf 'import { test } from "vitest";\ntest("x", () => {});\n' > src/lib/OAuthToken.test.ts
