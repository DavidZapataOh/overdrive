#!/usr/bin/env bash
set -eu
printf '# Demo\n' > README.md
mkdir -p db/migrations
printf 'CREATE TABLE posts (id int);\n' > db/migrations/0001_init.sql
