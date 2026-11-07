#!/usr/bin/env bash
set -eu
mkdir -p infra/deploy
printf 'echo release\n' > infra/deploy/release.sh
