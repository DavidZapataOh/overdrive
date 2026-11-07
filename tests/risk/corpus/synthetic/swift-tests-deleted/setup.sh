#!/usr/bin/env bash
set -eu
printf '# Demo\n' > README.md
mkdir -p Tests/AppTests
printf 'final class RouterTests {}\n' > Tests/AppTests/RouterTests.swift
