#!/usr/bin/env bash
set -eu
mkdir -p packages/web/docs/billing
printf '{"title": "Invoices"}\n' > packages/web/docs/billing/nav.json
