#!/usr/bin/env bash
set -eu
printf 'const lock = new Mutex();\n' >> src/jobs.ts
