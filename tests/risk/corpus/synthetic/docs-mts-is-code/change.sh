#!/usr/bin/env bash
set -eu
mkdir -p apps/docs/src/billing
printf 'const lock = new Mutex();\n' > apps/docs/src/billing/pay.mts
