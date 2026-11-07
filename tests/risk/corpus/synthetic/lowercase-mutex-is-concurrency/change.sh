#!/usr/bin/env bash
set -eu
printf '#include <mutex>\nstd::mutex guard;\n' > src/cache.cpp
