#!/usr/bin/env bash
set -eu
printf 'export type Id = string;\nexport type Slug = string;\n' > src/types.d.ts
