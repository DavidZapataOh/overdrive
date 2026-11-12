#!/usr/bin/env bash
set -eu
printf 'module.exports = [{ ignores: ["dist/**", "coverage/**"] }];\n' > eslint.config.js
