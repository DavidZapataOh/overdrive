#!/usr/bin/env bash
set -eu
mkdir -p src/tenants
printf 'export const resolve = (host: string) => host.split(".")[0];\n' > src/tenants/resolve.ts
printf 'import { test } from "vitest";\ntest("resolve", () => {});\n' > src/tenants/resolve.test.ts
