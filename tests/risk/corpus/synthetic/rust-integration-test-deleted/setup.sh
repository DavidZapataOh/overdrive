#!/usr/bin/env bash
set -eu
printf '# Demo\n' > README.md
mkdir -p tests
printf '#[test]\nfn parses() {}\n' > tests/parse.rs
