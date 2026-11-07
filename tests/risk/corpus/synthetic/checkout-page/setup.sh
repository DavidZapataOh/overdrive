#!/usr/bin/env bash
set -eu
printf '# Demo\n' > README.md
mkdir -p app/checkout
printf 'export default function Page() { return null; }\n' > app/checkout/page.tsx
printf 'import { test } from "vitest";\ntest("page", () => {});\n' > app/checkout/page.test.tsx
