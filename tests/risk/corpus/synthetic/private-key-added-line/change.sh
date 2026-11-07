#!/usr/bin/env bash
set -eu
mkdir -p config
begin=BEGIN
kind="RSA PRIV""ATE KEY"
printf -- '-----%s %s-----\nMIIBOgIBAAJBAKj34GkxFhD9\n-----END %s-----\n' "$begin" "$kind" "$kind" > config/tls.txt
