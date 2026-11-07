#!/usr/bin/env bash
set -eu
printf '# Demo\n' > README.md
printf '{ "name": "demo", "version": "1.0.0" }\n' > package.json
printf 'export default {};\n' > vitest.config.ts
