#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2028
# Tests for the risk corpus runner. Classifiers here are stubs; the real one is never invoked.

corpus_runner() {
  printf '%s/risk/run-corpus.sh\n' "$(cd "$(dirname "$RUNNER")" && pwd)"
}

sha256_lines() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$@"
  else
    shasum -a 256 "$@"
  fi
}

# Freezes every file under the corpus dir except SHA256SUMS itself.
freeze() {
  (
    cd "$1" || exit 1
    find . -type f ! -name SHA256SUMS | sed 's|^\./||' | LC_ALL=C sort > ../files.list
    # shellcheck disable=SC2046
    sha256_lines $(cat ../files.list) > SHA256SUMS
  )
}

# stub_classifier PATH LANE [ITEM...] writes a classifier that logs its arguments.
stub_classifier() {
  local path=$1 lane=$2 item
  shift 2
  {
    echo '#!/usr/bin/env bash'
    printf 'printf "%%s\\n" "$*" >> "%s.log"\n' "$path"
    printf 'echo "lane %s"\n' "$lane"
    for item in "$@"; do
      printf 'echo "item %s %s floor path x"\n' "$item" "$lane"
    done
    echo 'echo "next x"'
    echo 'echo "Risk: x"'
  } > "$path"
  chmod +x "$path"
}

add_case() {
  local dir=$1/synthetic/$2
  mkdir -p "$dir"
  printf '#!/usr/bin/env bash\nprintf "a\\n" > README.md\n' > "$dir/setup.sh"
  printf '#!/usr/bin/env bash\n%s\n' "$3" > "$dir/change.sh"
  printf 'lane %s\nitems %s\n' "$4" "$5" > "$dir/expected"
}

one_critical_case() {
  mkdir corpus
  add_case corpus auth-login 'mkdir -p src/auth && printf "x\n" > src/auth/login.md' critical auth
  freeze corpus
}

test_runner_reports_under_classification() {
  one_critical_case
  stub_classifier "$PWD/stub" direct
  local out rc=0
  out=$(OVERDRIVE_BIN="$PWD/stub" bash "$(corpus_runner)" --synthetic corpus/synthetic 2>&1) || rc=$?
  assert_eq 1 "$rc" "exit code"
  assert_line "$out" "UNDER auth-login critical:auth direct:none"
  assert_file_contains stub.log '^risk --repo .+ --worktree$'
  printf '%s\n' "$out" | grep -qE '^under=1 over=0 critical_recall=0\.00 over_rate=0\.00 '
}

test_runner_passes_matching_classifier() {
  one_critical_case
  stub_classifier "$PWD/stub" critical auth
  local out
  out=$(OVERDRIVE_BIN="$PWD/stub" bash "$(corpus_runner)" --synthetic corpus/synthetic)
  assert_line "$out" "PASS auth-login critical:auth critical:auth"
  assert_line "$out" "under=0 over=0 critical_recall=1.00 over_rate=0.00 item_precision.auth=1.00 item_recall.auth=1.00"
}

test_runner_reports_wrong_items_without_failing() {
  one_critical_case
  stub_classifier "$PWD/stub" critical auth money
  local out
  out=$(OVERDRIVE_BIN="$PWD/stub" bash "$(corpus_runner)" --synthetic corpus/synthetic)
  assert_line "$out" "ITEMS auth-login critical:auth critical:auth,money"
  printf '%s\n' "$out" | grep -qE ' item_precision\.money=0\.00 item_recall\.money=n/a$'
}

test_runner_fails_on_over_rate_above_quarter() {
  mkdir corpus
  add_case corpus docs-a 'printf "b\n" >> README.md' direct none
  add_case corpus docs-b 'printf "c\n" >> README.md' direct none
  freeze corpus
  stub_classifier "$PWD/stub" standard
  local out rc=0
  out=$(OVERDRIVE_BIN="$PWD/stub" bash "$(corpus_runner)" --synthetic corpus/synthetic) || rc=$?
  assert_eq 1 "$rc" "exit code"
  assert_line "$out" "OVER docs-a direct:none standard:none"
  assert_line "$out" "under=0 over=2 critical_recall=1.00 over_rate=1.00"
}

test_runner_ships_project_risk_map_in_baseline() {
  mkdir corpus
  add_case corpus mapped 'printf "b\n" >> README.md' critical copy
  printf 'path README.md copy\n' > corpus/synthetic/mapped/risk-map.conf
  freeze corpus
  {
    echo '#!/usr/bin/env bash'
    echo 'repo=$3'
    echo 'git -C "$repo" show HEAD:.overdrive/risk-map.conf >/dev/null || exit 9'
    echo 'git -C "$repo" diff --quiet HEAD -- README.md && exit 9'
    echo 'printf "lane critical\nitem copy critical map path README.md\n"'
  } > stub
  chmod +x stub
  local out
  out=$(OVERDRIVE_BIN="$PWD/stub" bash "$(corpus_runner)" --synthetic corpus/synthetic)
  assert_line "$out" "PASS mapped critical:copy critical:copy"
}

test_runner_refuses_changed_labels() {
  one_critical_case
  printf 'lane direct\nitems none\n' > corpus/synthetic/auth-login/expected
  stub_classifier "$PWD/stub" critical auth
  local out rc=0
  out=$(OVERDRIVE_BIN="$PWD/stub" bash "$(corpus_runner)" --synthetic corpus/synthetic 2>&1) || rc=$?
  assert_eq 2 "$rc" "exit code"
  assert_line "$out" "run-corpus: labels differ from SHA256SUMS: synthetic/auth-login/expected"
  [ ! -e stub.log ]
}

test_runner_refuses_unfrozen_case() {
  one_critical_case
  add_case corpus extra 'printf "b\n" >> README.md' direct none
  stub_classifier "$PWD/stub" critical auth
  local out rc=0
  out=$(OVERDRIVE_BIN="$PWD/stub" bash "$(corpus_runner)" --synthetic corpus/synthetic 2>&1) || rc=$?
  assert_eq 2 "$rc" "exit code"
  printf '%s\n' "$out" | grep -qF 'synthetic/extra/'
}

test_runner_fails_when_classifier_missing() {
  one_critical_case
  local out rc=0
  out=$(OVERDRIVE_BIN="$PWD/missing" bash "$(corpus_runner)" --synthetic corpus/synthetic 2>&1) || rc=$?
  assert_eq 2 "$rc" "exit code"
  assert_line "$out" "run-corpus: classifier not found: $PWD/missing"
}

test_runner_counts_classifier_crash_as_under() {
  mkdir corpus
  add_case corpus docs 'printf "b\n" >> README.md' direct none
  freeze corpus
  printf '#!/usr/bin/env bash\necho boom >&2\nexit 1\n' > stub
  chmod +x stub
  local out rc=0
  out=$(OVERDRIVE_BIN="$PWD/stub" bash "$(corpus_runner)" --synthetic corpus/synthetic 2>&1) || rc=$?
  assert_eq 1 "$rc" "exit code"
  assert_line "$out" "UNDER docs direct:none error:none # exit 1: boom"
}

test_runner_never_runs_contributor_hooks_in_fixtures() {
  mkdir corpus hooks
  add_case corpus docs 'printf "b\n" >> README.md' direct none
  freeze corpus
  printf '#!/bin/sh\nexit 1\n' > hooks/pre-commit
  chmod +x hooks/pre-commit
  printf '[core]\n\thooksPath = %s\n' "$PWD/hooks" > global.gitconfig
  stub_classifier "$PWD/stub" direct
  local out
  out=$(GIT_CONFIG_GLOBAL="$PWD/global.gitconfig" OVERDRIVE_BIN="$PWD/stub" \
    bash "$(corpus_runner)" --synthetic corpus/synthetic)
  assert_line "$out" "PASS docs direct:none direct:none"
}

# Upstream repo with a root commit, a plain commit and a merge commit.
make_upstream() {
  local up=$1
  mkdir -p "$up"
  git init -q "$up"
  git -C "$up" config user.name Test
  git -C "$up" config user.email test@example.com
  git -C "$up" config commit.gpgsign false
  printf 'a\n' > "$up/a.txt"
  git -C "$up" add a.txt
  git -C "$up" commit -q -m root
  git -C "$up" checkout -q -b side
  printf 'b\n' > "$up/b.txt"
  git -C "$up" add b.txt
  git -C "$up" commit -q -m side
  git -C "$up" checkout -q -
  printf 'c\n' > "$up/c.txt"
  git -C "$up" add c.txt
  git -C "$up" commit -q -m plain
  git -C "$up" merge -q --no-ff -m merge side
  git -C "$up" config uploadpack.allowFilter true
}

test_runner_tsv_ranges_and_clone_into_empty_cache() {
  make_upstream remote/acme/widget.git
  local up=remote/acme/widget.git root plain merge empty
  root=$(git -C "$up" rev-list --max-parents=0 HEAD)
  plain=$(git -C "$up" rev-parse HEAD^1)
  merge=$(git -C "$up" rev-parse HEAD)
  empty=$(git -C "$up" hash-object -t tree --stdin </dev/null)
  mkdir corpus
  {
    printf 'acme/widget\t%s\tdirect\tnone\troot commit\n' "$root"
    printf 'acme/widget\t%s\tdirect\tnone\tplain commit\n' "$plain"
    printf 'acme/widget\t%s\tdirect\tnone\tmerge commit\n' "$merge"
  } > corpus/units.tsv
  freeze corpus
  stub_classifier "$PWD/stub" direct
  local out
  out=$(OVERDRIVE_BIN="$PWD/stub" OVERDRIVE_CORPUS_REMOTE="$PWD/remote" \
    bash "$(corpus_runner)" --tsv corpus/units.tsv --clone-cache cache 2>&1)
  assert_eq true "$(git -C cache/widget.git rev-parse --is-bare-repository)"
  local cache_dir
  cache_dir=$(cd cache/widget.git && pwd)
  assert_line "$(cat stub.log)" "risk --repo $cache_dir --diff $empty..$root"
  assert_line "$(cat stub.log)" "risk --repo $cache_dir --diff $plain^..$plain"
  assert_line "$(cat stub.log)" "risk --repo $cache_dir --diff $merge^1..$merge"
  assert_line "$out" "PASS acme/widget@${merge:0:12} direct:none direct:none"
}

test_runner_fetches_missing_commit_into_cache() {
  make_upstream remote/acme/widget.git
  git clone -q --bare remote/acme/widget.git cache/widget.git
  local up=remote/acme/widget.git sha
  printf 'd\n' > d.txt
  git -C "$up" checkout -q -b later
  cp d.txt "$up/d.txt"
  git -C "$up" add d.txt
  git -C "$up" commit -q -m later
  sha=$(git -C "$up" rev-parse HEAD)
  git -C "$up" config uploadpack.allowAnySHA1InWant true
  mkdir corpus
  printf 'acme/widget\t%s\tdirect\tnone\tlater\n' "$sha" > corpus/units.tsv
  freeze corpus
  git -C cache/widget.git remote set-url origin "$PWD/$up"
  stub_classifier "$PWD/stub" direct
  local out rc=0
  out=$(OVERDRIVE_BIN="$PWD/stub" bash "$(corpus_runner)" --tsv corpus/units.tsv --clone-cache cache 2>&1) || rc=$?
  assert_eq 0 "$rc" "exit code"
  assert_line "$out" "PASS acme/widget@${sha:0:12} direct:none direct:none"
  git -C cache/widget.git cat-file -e "$sha^{commit}"
}

test_runner_rejects_malformed_tsv_row() {
  mkdir corpus
  printf 'acme/widget\tabc\tsevere\tnone\tbad lane\n' > corpus/units.tsv
  freeze corpus
  stub_classifier "$PWD/stub" direct
  local out rc=0
  out=$(OVERDRIVE_BIN="$PWD/stub" bash "$(corpus_runner)" --tsv corpus/units.tsv --clone-cache cache 2>&1) || rc=$?
  assert_eq 2 "$rc" "exit code"
  printf '%s\n' "$out" | grep -qF 'corpus/units.tsv:1'
}
