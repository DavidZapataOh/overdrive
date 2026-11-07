#!/usr/bin/env bash
set -eu
mkdir -p config
printf '{ "client": "web" }\n' > config/credentials.json
