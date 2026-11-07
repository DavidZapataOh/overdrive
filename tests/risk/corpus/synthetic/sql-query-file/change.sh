#!/usr/bin/env bash
set -eu
mkdir -p db/queries
printf 'SELECT id FROM posts;\n' > db/queries/report.sql
