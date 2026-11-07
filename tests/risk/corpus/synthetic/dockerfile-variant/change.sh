#!/usr/bin/env bash
set -eu
mkdir -p docker
printf 'FROM node:22-alpine\n' > docker/Dockerfile.prod
