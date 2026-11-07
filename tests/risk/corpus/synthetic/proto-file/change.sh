#!/usr/bin/env bash
set -eu
mkdir -p proto
printf 'syntax = "proto3";\nmessage User { string id = 1; }\n' > proto/user.proto
