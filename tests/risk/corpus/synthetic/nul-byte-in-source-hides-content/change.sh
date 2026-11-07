#!/usr/bin/env bash
set -eu
printf 'const lock = new Mutex(); // \000\n' >> src/jobs.ts
