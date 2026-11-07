#!/usr/bin/env bash
set -eu
printf '# Demo\n' > README.md
mkdir -p app/src/test/kotlin
printf 'class LedgerTests\n' > app/src/test/kotlin/LedgerTests.kt
