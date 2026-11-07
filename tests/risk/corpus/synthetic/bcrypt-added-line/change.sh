#!/usr/bin/env bash
set -eu
printf 'import bcrypt from "bcrypt";\nexport const hash = (s: string) => bcrypt.hash(s, 12);\n' > src/users/hash.ts
