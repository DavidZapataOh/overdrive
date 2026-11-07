#!/usr/bin/env bash
set -eu
printf 'export const banner = () => "node";\n' >> apps/web/scripts/vercel-build.mjs
