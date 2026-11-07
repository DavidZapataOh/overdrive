#!/usr/bin/env bash
set -eu
printf '# Demo\n' > README.md
mkdir -p src/jobs
printf 'export const claim = "select id from jobs limit 1";\n' > src/jobs/claim.ts
printf 'import { test } from "vitest";\ntest("claim", () => {});\n' > src/jobs/claim.test.ts
