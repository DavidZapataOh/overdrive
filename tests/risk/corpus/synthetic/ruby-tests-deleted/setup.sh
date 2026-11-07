#!/usr/bin/env bash
set -eu
printf '# Demo\n' > README.md
mkdir -p spec test
printf 'describe User do\nend\n' > spec/user_spec.rb
printf 'class TestOrder; end\n' > test/test_order.rb
printf 'class CartTest; end\n' > test/cart_test.rb
