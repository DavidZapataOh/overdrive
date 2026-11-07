#!/usr/bin/env bash
set -eu
printf '# Demo\n' > README.md
mkdir -p schema
printf 'type Query { me: String }\n' > schema/schema.graphql
