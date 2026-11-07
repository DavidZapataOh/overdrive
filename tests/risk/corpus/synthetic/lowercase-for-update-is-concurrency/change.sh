#!/usr/bin/env bash
set -eu
printf 'export const claim = "select id from jobs limit 1 for update";\n' > src/jobs/claim.ts
