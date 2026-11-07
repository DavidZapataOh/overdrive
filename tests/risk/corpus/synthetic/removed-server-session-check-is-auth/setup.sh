#!/usr/bin/env bash
set -eu
printf '# Demo\n' > README.md
mkdir -p src/pages
printf 'const s = await getServerSession(req);\nexport const page = s;\n' > src/pages/account.ts
printf 'import { test } from "vitest";\ntest("x", () => {});\n' > src/pages/account.test.ts
