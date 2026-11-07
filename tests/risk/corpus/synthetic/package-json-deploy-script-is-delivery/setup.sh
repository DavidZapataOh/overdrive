#!/usr/bin/env bash
set -eu
printf '# Demo\n' > README.md
mkdir -p apps/web
printf '{\n  "scripts": {\n    "build": "next build"\n  }\n}\n' > apps/web/package.json
