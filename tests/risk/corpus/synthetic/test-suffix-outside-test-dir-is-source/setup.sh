#!/usr/bin/env bash
set -eu
printf '# Demo\n' > README.md
mkdir -p src/main/java/com/acme
printf 'class LoadTest {}\n' > src/main/java/com/acme/LoadTest.java
