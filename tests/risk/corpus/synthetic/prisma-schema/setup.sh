#!/usr/bin/env bash
set -eu
printf '# Demo\n' > README.md
mkdir -p prisma
printf 'model Post {\n  id Int @id\n}\n' > prisma/schema.prisma
