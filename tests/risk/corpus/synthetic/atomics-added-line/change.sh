#!/usr/bin/env bash
set -eu
printf 'export const bump = () => Atomics.add(counter, 0, 1);\n' >> src/counter.js
