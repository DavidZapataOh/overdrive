#!/usr/bin/env bash
set -eu
printf '# Demo\n' > README.md
mkdir -p tests
printf 'def test_a():\n    pass\n\n\ndef test_b():\n    pass\n\n\ndef test_c():\n    pass\n' > tests/test_math.py
