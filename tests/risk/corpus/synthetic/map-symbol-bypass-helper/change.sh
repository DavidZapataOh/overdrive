#!/usr/bin/env bash
set -eu
printf 'import { bypassHeaders } from "./e2e/bypass";\nexport default { use: { extraHTTPHeaders: bypassHeaders() } };\n' > playwright.config.ts
