#!/usr/bin/env bash
set -eu
printf '# Demo\n' > README.md
mkdir -p "apps/web/src/app/páginas legales"
printf 'export default function Page() { return null; }\n' > "apps/web/src/app/páginas legales/page.tsx"
printf 'import { test } from "vitest";\ntest("page", () => {});\n' > "apps/web/src/app/páginas legales/page.test.tsx"
