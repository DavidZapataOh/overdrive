#!/usr/bin/env bash
set -eu
printf '# Demo\n' > README.md
mkdir -p app/dashboard
printf 'export default async function Page() { return null; }\n' > app/dashboard/page.tsx
printf 'import { test } from "vitest";\ntest("page", () => {});\n' > app/dashboard/page.test.tsx
