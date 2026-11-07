#!/usr/bin/env bash
set -eu
printf 'model Tag {\n  id Int @id\n}\n' >> prisma/schema.prisma
