#!/usr/bin/env bash
set -eu
printf '# Demo\n' > README.md
mkdir -p src test
printf 'export const route = 1;\n' > src/app.ts
printf 'import { route } from "../src/app";\nexport const get = () => route;\n' > test/helpers.ts
