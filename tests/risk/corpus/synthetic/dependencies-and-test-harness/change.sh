#!/usr/bin/env bash
set -eu
printf '{ "name": "demo", "version": "1.0.1" }\n' > package.json
printf 'export default { test: {} };\n' > vitest.config.ts
