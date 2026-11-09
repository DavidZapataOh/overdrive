#!/usr/bin/env bash
# shellcheck disable=SC2016
. "$(dirname "$0")/../../../_lib/fixtures.sh" || exit 1
. "$(dirname "$0")/../../shop-project.sh" || exit 1
e2e_shop_project || exit 1
fx_file README.md '# Shop

A small shop library. Customers recieve a confirmation email after every order. Run the tests with npm test.'
fx_commit "Document order emails"
