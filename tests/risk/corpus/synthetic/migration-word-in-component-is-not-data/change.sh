#!/usr/bin/env bash
set -eu
mkdir -p src/ui
printf 'export const MigrationBanner = () => null;\n' > src/ui/migration-banner.tsx
printf 'import { test } from "vitest";\ntest("banner", () => {});\n' > src/ui/migration-banner.test.tsx
