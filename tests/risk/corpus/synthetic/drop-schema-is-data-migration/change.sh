#!/usr/bin/env bash
set -eu
printf 'export const reset = "DROP SCHEMA scratch CASCADE";\n' > src/db/reset.ts
