#!/usr/bin/env bash
. "$(dirname "$0")/../../../_lib/fixtures.sh" || exit 1
. "$(dirname "$0")/shop-project.sh" || exit 1
rg_shop_project standard on 0 yes
