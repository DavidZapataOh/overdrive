#!/usr/bin/env bash
set -eu
mkdir -p src/misc
git mv src/auth/x.ts src/misc/x.ts
git mv src/auth/x.test.ts src/misc/x.test.ts
