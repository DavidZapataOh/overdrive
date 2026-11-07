#!/usr/bin/env bash
set -eu
printf 'export default { test: { globals: true } };\n' > vitest.config.ts
