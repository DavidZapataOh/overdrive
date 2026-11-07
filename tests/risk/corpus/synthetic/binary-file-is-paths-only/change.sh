#!/usr/bin/env bash
set -eu
mkdir -p assets
# Secret-shaped bytes inside binary content must never be read as text.
prefix=AK
printf '\000\001\002%sIA%s\000\377' "$prefix" "Q7X2M4P9R3T6V8W1" > assets/blob.bin
