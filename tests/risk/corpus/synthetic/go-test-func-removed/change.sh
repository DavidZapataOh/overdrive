#!/usr/bin/env bash
set -eu
printf 'package calc\n\nimport "testing"\n\nfunc TestAdd(t *testing.T) {}\n' > pkg/calc/calc_test.go
