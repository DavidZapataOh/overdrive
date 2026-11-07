#!/usr/bin/env bash
set -eu
printf '{\n  "scripts": {\n    "build": "next build",\n    "deploy": "vercel deploy --prod"\n  }\n}\n' > apps/web/package.json
