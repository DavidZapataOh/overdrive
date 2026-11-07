#!/usr/bin/env bash
set -eu
printf '# Demo\n' > README.md
mkdir -p pkg/calc
printf 'package calc\n\nimport "testing"\n\nfunc TestAdd(t *testing.T) {}\n\nfunc TestSub(t *testing.T) {}\n' > pkg/calc/calc_test.go
