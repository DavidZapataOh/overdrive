#!/usr/bin/env bash
set -eu
printf 'Workers claim jobs with SELECT ... FOR UPDATE SKIP LOCKED.\n' >> README.md
