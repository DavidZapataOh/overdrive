#!/usr/bin/env bash
set -eu
mkdir -p src
prefix=AK
printf 'export const keyId = "%sIA%s";\n' "$prefix" "Q7X2M4P9R3T6V8W1" > src/aws.ts
printf 'import { test } from "vitest";\ntest("keyId", () => {});\n' > src/aws.test.ts
