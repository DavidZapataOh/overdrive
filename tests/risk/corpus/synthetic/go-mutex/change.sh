#!/usr/bin/env bash
set -eu
mkdir -p pkg/cache
printf 'package cache\n\nimport "sync"\n\ntype Store struct {\n\tmu sync.Mutex\n}\n' > pkg/cache/lock.go
printf 'package cache\n\nimport "testing"\n\nfunc TestStore(t *testing.T) {}\n' > pkg/cache/lock_test.go
