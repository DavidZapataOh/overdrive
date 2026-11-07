#!/usr/bin/env bash
set -eu
printf '# Demo\n' > README.md
mkdir -p Web.Tests
printf 'public class UsersTests {}\n' > Web.Tests/UsersTests.cs
