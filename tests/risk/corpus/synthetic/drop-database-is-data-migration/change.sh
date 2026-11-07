#!/usr/bin/env bash
set -eu
printf 'export const reset = "drop database if exists scratch";\n' > src/db/reset.ts
