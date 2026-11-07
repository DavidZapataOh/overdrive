#!/usr/bin/env bash
set -eu
printf '# Demo\n' > README.md
printf 'module example.com/demo\n\ngo 1.23\n' > go.mod
