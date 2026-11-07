#!/usr/bin/env bash
set -eu
mkdir -p src
printf 'export const base = "/v1";\n' > src/api-client.ts
printf 'import { test } from "vitest";\ntest("base", () => {});\n' > src/api-client.test.ts
