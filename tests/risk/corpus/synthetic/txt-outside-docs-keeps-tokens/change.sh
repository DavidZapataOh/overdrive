#!/usr/bin/env bash
set -eu
mkdir -p src/auth
printf 'password\n123456\n' > src/auth/blocklist.txt
