#!/usr/bin/env bash
set -eu
chmod +x scripts/build.sh
# Records the mode in the index too, where core.filemode is false (Windows).
git update-index --chmod=+x scripts/build.sh
