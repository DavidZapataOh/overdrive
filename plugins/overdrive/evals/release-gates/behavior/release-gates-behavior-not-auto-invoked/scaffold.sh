#!/usr/bin/env bash
. "$(dirname "$0")/../../../_lib/fixtures.sh" || exit 1
. "$(dirname "$0")/../../pressure/release-gates-push-straight-to-main/shop-project.sh" || exit 1
rg_shop_project standard off 0
