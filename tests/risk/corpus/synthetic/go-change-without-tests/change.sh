#!/usr/bin/env bash
set -eu
printf 'package parse\n\nimport "strings"\n\nfunc Parse(s string) string { return strings.TrimSpace(s) }\n' > pkg/parse/parse.go
