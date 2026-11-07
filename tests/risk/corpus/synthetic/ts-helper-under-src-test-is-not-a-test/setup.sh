#!/usr/bin/env bash
set -eu
printf '# Demo\n' > README.md
mkdir -p packages/core/src/test
printf 'export const mockLogger = {};\n' > packages/core/src/test/utils.ts
