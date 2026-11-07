#!/usr/bin/env bash
set -eu
printf '# Demo\n' > README.md
mkdir -p app tests
printf 'class User:\n    pass\n' > app/models.py
printf 'def test_user():\n    pass\n' > tests/test_models.py
