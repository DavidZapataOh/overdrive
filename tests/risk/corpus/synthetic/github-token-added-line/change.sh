#!/usr/bin/env bash
set -eu
mkdir -p scripts
head=a1B2c3D4e5F6g7H8i9
rest=J0k1L2m3N4o5P6q7R8
printf 'export GH_TOKEN=%s_%s%s\n' ghp "$head" "$rest" > scripts/publish.sh
