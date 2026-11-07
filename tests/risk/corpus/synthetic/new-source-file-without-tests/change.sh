#!/usr/bin/env bash
set -eu
mkdir -p lib
printf 'def slug(s):\n    return s.lower()\n' > lib/slug.py
