#!/usr/bin/env bash
set -eu
printf '// ajusta el cobro mensual\nexport const monthly = 12;\n' >> src/fees.ts
