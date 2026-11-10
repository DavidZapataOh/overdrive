#!/usr/bin/env bash
# Tests for overdrive review-package.

plugin_dir() { printf '%s\n' "$(dirname "$(dirname "$RUNNER")")/plugins/overdrive"; }

# copy_plugin DIR [RISK_BODY]: the real plugin with libexec/overdrive-risk replaced by a
# stub running RISK_BODY, or removed when RISK_BODY is empty.
copy_plugin() {
  SANDBOX=${1%/*}
  mkdir -p "$1"
  cp -R "$(plugin_dir)/." "$1/"
  mkdir -p "$1/libexec"
  rm -f "$1/libexec/overdrive-risk"
  if [ -n "${2-}" ]; then
    printf '#!/usr/bin/env bash\n%s\n' "$2" > "$1/libexec/overdrive-risk"
  fi
}

od() { "$BASH" "$SANDBOX/fp/bin/overdrive" "$@"; }

# TMPDIR may end in a slash; the library collapses repeated slashes.
sq() {
  local s=$1 slash=/
  s=${s//$slash$slash/$slash}
  printf '%s' "$s"
}

# two_commits REPO: base and head shas on stdout, one per line.
two_commits() {
  git -C "$1" rev-parse HEAD
  commit_file "$1" "src/a b.ts" "export const x = 1;"
  git -C "$1" rev-parse HEAD
}

test_package_refuses_non_ancestor() {
  copy_plugin "$PWD/fp" 'printf "lane direct\nRisk: direct — none\n"'
  local repo base side rc=0
  repo=$(make_repo)
  base=$(git -C "$repo" rev-parse HEAD)
  commit_file "$repo" one.txt one
  git -C "$repo" checkout -q -b side "$base"
  commit_file "$repo" two.txt two
  side=$(git -C "$repo" rev-parse HEAD)
  git -C "$repo" checkout -q -
  (cd "$repo" && od review-package --base "$(git rev-parse HEAD)" --head "$side") >/dev/null 2>&1 || rc=$?
  assert_eq 65 "$rc"
  [ ! -d "$repo/.overdrive/run/reviews" ] || [ -z "$(ls "$repo/.overdrive/run/reviews")" ]
}

test_package_refuses_empty_range() {
  copy_plugin "$PWD/fp" 'printf "lane direct\nRisk: direct — none\n"'
  local repo head rc=0
  repo=$(make_repo)
  head=$(git -C "$repo" rev-parse HEAD)
  (cd "$repo" && od review-package --base "$head" --head "$head") >/dev/null 2>&1 || rc=$?
  assert_eq 65 "$rc"
}

test_package_refuses_unknown_revision() {
  copy_plugin "$PWD/fp" 'printf "lane direct\nRisk: direct — none\n"'
  local repo rc=0
  repo=$(make_repo)
  (cd "$repo" && od review-package --base nosuchrev --head HEAD) >/dev/null 2>&1 || rc=$?
  assert_eq 65 "$rc"
  rc=0
  (cd "$repo" && od review-package --base HEAD) >/dev/null 2>&1 || rc=$?
  assert_eq 64 "$rc"
  rc=0
  (cd "$repo" && od review-package --base HEAD --head HEAD --lane fast) >/dev/null 2>&1 || rc=$?
  assert_eq 64 "$rc"
}

test_package_contains_risk_section() {
  # The stub echoes its arguments so the test sees the exact range it was given.
  copy_plugin "$PWD/fp" 'printf "lane standard\nitem tests standard map path x\nnote args %s\nnext Short.\nRisk: standard — tests\n" "$*"'
  local repo base head out file
  repo=$(make_repo)
  { read -r base; read -r head; } <<EOS
$(two_commits "$repo")
EOS
  write_file "$repo" docs/brief.md brief
  out=$(cd "$repo/src" && od review-package --base "$base" --head "$head" --brief ../docs/brief.md)
  file=$(sq "$repo")/.overdrive/run/reviews/${base:0:7}-${head:0:7}.md
  assert_eq "$file" "$out"
  [ -f "$file" ]
  assert_line "$(sed -n 1p "$file")" '# Review package'
  local body
  body=$(cat "$file")
  assert_line "$body" "Range: $base..$head"
  # Reviewers run the CLI by this absolute path: bin/ is not on their PATH.
  assert_line "$body" "Overdrive CLI: $(cd "$PWD/fp/bin" && pwd -P)/overdrive"
  assert_line "$body" "Brief: $(cd "$repo/docs" && pwd -P)/brief.md"
  assert_line "$body" 'Lane: standard'
  assert_line "$body" 'lane standard'
  assert_line "$body" "note args --diff $base..$head"
  assert_line "$body" 'Risk: standard — tests'
  assert_line "$body" "$(git -C "$repo" log --oneline -1 "$head")"
  assert_file_contains "$file" 'src/a b\.ts \| 1 \+'
  assert_line "$body" '+export const x = 1;'
  # Sections come in the documented order.
  assert_eq '## Risk|## Commits|## Diff stat|## Diff' "$(grep '^## ' "$file" | paste -sd '|' -)"
  # The run directory ignores itself so packages are never committed.
  assert_eq '*' "$(cat "$repo/.overdrive/run/.gitignore")"
}

test_package_lane_never_lowered_by_request() {
  copy_plugin "$PWD/fp" 'printf "lane critical\nRisk: critical — auth\n"'
  local repo base head file
  repo=$(make_repo)
  { read -r base; read -r head; } <<EOS
$(two_commits "$repo")
EOS
  file=$(cd "$repo" && od review-package --base "$base" --head "$head" --lane direct)
  assert_file_contains "$file" '^Lane: critical$'
  assert_no_line "$(cat "$file")" '^note lane raised'
  copy_plugin "$PWD/fp" 'printf "lane direct\nnext Work inline.\nRisk: direct — none\n"'
  file=$(cd "$repo" && od review-package --base "$base" --head "$head" --lane standard)
  assert_file_contains "$file" '^Lane: standard$'
  assert_file_contains "$file" '^Brief: none$'
  # The raise is recorded among the classifier notes, before next and the Risk line.
  assert_eq 'lane direct|note lane raised by caller: direct → standard|next Work inline.|Risk: direct — none' \
    "$(sed -n '/^## Risk$/,/^## Commits$/p' "$file" | grep -v '^#' | grep . | paste -sd '|' -)"
}

test_package_risk_unavailable_fails_closed() {
  copy_plugin "$PWD/fp" ''
  local repo base head file body
  repo=$(make_repo)
  { read -r base; read -r head; } <<EOS
$(two_commits "$repo")
EOS
  file=$(cd "$repo" && od review-package --base "$base" --head "$head" --lane direct)
  body=$(cat "$file")
  assert_line "$body" 'Lane: critical'
  assert_line "$body" 'lane critical'
  assert_line "$body" 'note classification unavailable: overdrive risk is not installed'
  assert_line "$body" 'Risk: critical — classification-failed'
}

test_package_risk_failure_fails_closed() {
  copy_plugin "$PWD/fp" 'echo "lane direct"; echo "boom: map unreadable" >&2; exit 2'
  local repo base head file body
  repo=$(make_repo)
  { read -r base; read -r head; } <<EOS
$(two_commits "$repo")
EOS
  file=$(cd "$repo" && od review-package --base "$base" --head "$head")
  body=$(cat "$file")
  assert_line "$body" 'Lane: critical'
  assert_line "$body" 'note classification unavailable: overdrive risk exited 2: boom: map unreadable'
  assert_no_line "$body" '^lane direct$'
  # Output that breaks the contract counts as a failure too.
  copy_plugin "$PWD/fp" 'echo "something else"'
  file=$(cd "$repo" && od review-package --base "$base" --head "$head")
  assert_file_contains "$file" '^note classification unavailable: overdrive risk output does not match its contract$'
}

test_package_keeps_fail_closed_classifier_output() {
  copy_plugin "$PWD/fp" 'printf "lane critical\nitem classification-failed critical failure shallow\nnext Full.\nRisk: critical — classification-failed\n"; exit 3'
  local repo base head file
  repo=$(make_repo)
  { read -r base; read -r head; } <<EOS
$(two_commits "$repo")
EOS
  file=$(cd "$repo" && od review-package --base "$base" --head "$head")
  assert_file_contains "$file" '^item classification-failed critical failure shallow$'
  assert_file_contains "$file" '^Lane: critical$'
}

test_package_outside_git_fails() {
  copy_plugin "$PWD/fp" 'printf "lane direct\nRisk: direct — none\n"'
  mkdir plain
  local rc=0
  (cd plain && od review-package --base a --head b) >/dev/null 2>&1 || rc=$?
  assert_eq 1 "$rc"
}

# green_evidence REPO: record a passing run the way the builder does.
green_evidence() {
  (cd "$1" && od evidence green -- true) > /dev/null
}

test_package_names_the_green_evidence() {
  copy_plugin "$PWD/fp" 'printf "lane standard\nnext Short.\nRisk: standard — tests\n"'
  local repo base head out
  repo=$(make_repo)
  { read -r base; read -r head; } <<EOS
$(two_commits "$repo")
EOS
  out=$(cd "$repo" && od review-package --base "$base" --head "$head")
  assert_line "$(cat "$out")" 'Green evidence: none'
  green_evidence "$repo"
  green_evidence "$repo"
  out=$(cd "$repo" && od review-package --base "$base" --head "$head")
  assert_line "$(cat "$out")" "Green evidence: $(sq "$repo")/.overdrive/run/evidence/0002-green.md"
}

test_package_require_green_refuses_without_evidence() {
  copy_plugin "$PWD/fp" 'printf "lane standard\nnext Short.\nRisk: standard — tests\n"'
  local repo base head rc=0 out
  repo=$(make_repo)
  { read -r base; read -r head; } <<EOS
$(two_commits "$repo")
EOS
  out=$(cd "$repo" && od review-package --base "$base" --head "$head" --require-green 2>&1) || rc=$?
  assert_eq 65 "$rc" "exit code"
  assert_line "$out" 'overdrive: no green evidence: run overdrive evidence green -- <test command>, or pass --no-tests <reason> when nothing here is testable'
  [ ! -e "$repo/.overdrive/run/reviews" ] || [ -z "$(ls "$repo/.overdrive/run/reviews")" ]
  # Recorded evidence satisfies the gate.
  green_evidence "$repo"
  out=$(cd "$repo" && od review-package --base "$base" --head "$head" --require-green)
  [ -f "$out" ]
  # A stated reason does too, and the package carries it.
  rm -f "$repo"/.overdrive/run/evidence/*-green.md
  out=$(cd "$repo" && od review-package --base "$base" --head "$head" --require-green --no-tests "docs only")
  assert_line "$(cat "$out")" 'Green evidence: none (no tests: docs only)'
}

test_package_require_green_skips_direct_lane() {
  copy_plugin "$PWD/fp" 'printf "lane direct\nnext Work inline.\nRisk: direct — none\n"'
  local repo base head out
  repo=$(make_repo)
  { read -r base; read -r head; } <<EOS
$(two_commits "$repo")
EOS
  out=$(cd "$repo" && od review-package --base "$base" --head "$head" --require-green)
  [ -f "$out" ]
}
