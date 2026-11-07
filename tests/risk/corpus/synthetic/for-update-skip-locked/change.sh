#!/usr/bin/env bash
set -eu
printf 'export const claim = "SELECT id FROM jobs LIMIT 1 FOR UPDATE SKIP LOCKED";\n' > src/jobs/claim.ts
