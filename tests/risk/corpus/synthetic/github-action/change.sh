#!/usr/bin/env bash
set -eu
mkdir -p .github/actions/setup
printf 'name: setup\nruns:\n  using: composite\n  steps: []\n' > .github/actions/setup/action.yml
