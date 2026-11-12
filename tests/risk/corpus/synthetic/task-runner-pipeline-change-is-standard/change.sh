#!/usr/bin/env bash
set -eu
printf '{ "name": "demo", "scripts": { "build": "turbo run build", "typecheck": "turbo run typecheck" } }\n' > package.json
printf '{ "tasks": { "build": {}, "typecheck": { "dependsOn": ["^build"], "outputs": [] } } }\n' > turbo.json
