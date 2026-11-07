#!/usr/bin/env bash
set -eu
printf '# Demo\n' > README.md
mkdir -p pkg/parse
printf 'package parse\n\nfunc Parse(s string) string { return s }\n' > pkg/parse/parse.go
