#!/usr/bin/env bash
set -eu
printf '# Demo\n' > README.md
printf '{ "name": "demo", "scripts": { "build": "turbo run build" } }\n' > package.json
printf '{ "tasks": { "build": {} } }\n' > turbo.json
