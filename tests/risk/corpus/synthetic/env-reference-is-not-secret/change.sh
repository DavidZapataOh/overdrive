#!/usr/bin/env bash
set -eu
# shellcheck disable=SC2016
printf 'api_key: ${API_KEY}\n' >> config/app.yml
