#!/usr/bin/env bash
set -eu
printf '# Demo\n' > README.md
mkdir -p src/test/java/com/acme
printf 'class OrderTest {}\n' > src/test/java/com/acme/OrderTest.java
