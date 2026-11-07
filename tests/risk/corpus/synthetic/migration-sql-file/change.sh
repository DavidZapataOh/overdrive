#!/usr/bin/env bash
set -eu
printf 'CREATE INDEX posts_id ON posts (id);\n' > db/migrations/0002_index.sql
