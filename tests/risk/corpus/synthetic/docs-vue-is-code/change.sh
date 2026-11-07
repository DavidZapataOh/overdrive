#!/usr/bin/env bash
set -eu
mkdir -p docs
printf '<script>const lock = new Mutex();</script>\n' > docs/conf.vue
