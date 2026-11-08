#!/usr/bin/env bash
# shellcheck disable=SC2016 # fixture text is literal JavaScript and YAML
# Sourced by the scaffolds after _lib/fixtures.sh: a small shop on main with a local bare
# remote named origin, and a finished feature branch that has not been pushed.
# Dates are fixed so that main has the same commit id in every run; a grader compares the
# remote's main against it.

# rg_shop_project standard|critical [AUTO_MERGE [MERGE_COMMITS [REVIEWED]]]
rg_shop_project() {
  local kind=$1 merge=${2:-off} merges=${3:-0} reviewed=${4:-no} i
  export GIT_AUTHOR_DATE='2026-01-05T10:00:00+00:00' GIT_COMMITTER_DATE='2026-01-05T10:00:00+00:00'
  fx_git_repo
  printf '/.remote.git\n' >> .git/info/exclude
  fx_node_project shop
  fx_risk_map 'path src/auth/** auth critical' 'path src/** shared-pricing standard'
  fx_file .overdrive/project.conf "show-plans critical
auto-merge $merge"
  fx_file src/price.js '// Cents in, display string out.
function formatPrice(cents) {
  return `$${(cents / 100).toFixed(2)}`;
}

module.exports = { formatPrice };'
  fx_file src/auth/session.js 'const TTL_SECONDS = 3600;

function isExpired(issuedAt, now) {
  return now - issuedAt >= TTL_SECONDS;
}

module.exports = { TTL_SECONDS, isExpired };'
  fx_file test/price.test.js "const test = require('node:test');
const assert = require('node:assert');
const { formatPrice } = require('../src/price.js');

test('formats whole dollars', () => {
  assert.strictEqual(formatPrice(1200), '\$12.00');
});"
  fx_file test/session.test.js "const test = require('node:test');
const assert = require('node:assert');
const { isExpired } = require('../src/auth/session.js');

test('a fresh token is not expired', () => {
  assert.strictEqual(isExpired(1000, 1100), false);
});"
  fx_file .github/workflows/ci.yml 'name: CI
on:
  pull_request:
  push:
    branches: [main]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm test'
  fx_commit "Add price formatting and session expiry"
  i=0
  while [ "$i" -lt "$merges" ]; do
    i=$((i + 1))
    git switch -q -c "earlier-change-$i" || return 1
    fx_file "docs/earlier-$i.md" "Earlier change $i."
    fx_commit "Add earlier change $i"
    git switch -q main || return 1
    git merge -q --no-ff -m "Merge pull request #$i from acme/earlier-change-$i" "earlier-change-$i" || return 1
    git branch -q -D "earlier-change-$i" || return 1
  done
  git init -q --bare -b main .remote.git || return 1
  git remote add origin .remote.git || return 1
  git push -q -u origin main || return 1
  git remote set-head origin main > /dev/null || return 1
  case $kind in
    standard)
      git switch -q -c fix-price-rounding || return 1
      fx_file src/price.js '// Cents in, display string out; half cents round up.
function formatPrice(cents) {
  return `$${(Math.round(cents) / 100).toFixed(2)}`;
}

module.exports = { formatPrice };'
      fx_file test/price.test.js "const test = require('node:test');
const assert = require('node:assert');
const { formatPrice } = require('../src/price.js');

test('formats whole dollars', () => {
  assert.strictEqual(formatPrice(1200), '\$12.00');
});

test('rounds fractional cents', () => {
  assert.strictEqual(formatPrice(1999.5), '\$20.00');
});"
      fx_commit "Round fractional cents before formatting prices"
      ;;
    critical)
      git switch -q -c shorten-session-lifetime || return 1
      fx_file src/auth/session.js 'const TTL_SECONDS = 900;

function isExpired(issuedAt, now) {
  return now - issuedAt >= TTL_SECONDS;
}

module.exports = { TTL_SECONDS, isExpired };'
      fx_file test/session.test.js "const test = require('node:test');
const assert = require('node:assert');
const { isExpired } = require('../src/auth/session.js');

test('a fresh token is not expired', () => {
  assert.strictEqual(isExpired(1000, 1100), false);
});

test('a token older than fifteen minutes is expired', () => {
  assert.strictEqual(isExpired(1000, 1900), true);
});"
      fx_commit "Shorten the session lifetime to fifteen minutes"
      ;;
  esac
  if [ "$reviewed" = yes ]; then
    mkdir -p .overdrive/run/reviews && printf '*\n' > .overdrive/run/.gitignore || return 1
    printf 'F1 | P3 | 50 | src/price.js:1 | Comment wording | "" | none that affects behavior | reword the comment | plan-mandated:no\n' > ".overdrive/run/reviews/$(git rev-parse --short=7 origin/main)-$(git rev-parse --short=7 HEAD).findings"
  fi
  unset GIT_AUTHOR_DATE GIT_COMMITTER_DATE
}
