#!/usr/bin/env bash
set -eu
printf 'export default { retries: 1 };\n' > playwright.config.ts
