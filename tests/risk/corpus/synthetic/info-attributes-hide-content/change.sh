#!/usr/bin/env bash
set -eu
printf 'await db.execute("DROP TABLE jobs");\n' >> src/jobs.ts
