#!/usr/bin/env bash
# Performance budgets of overdrive risk: Linux 1 s, macOS 2 s, Windows Git Bash 5 s, where
# process creation costs about ten times as much.

# shellcheck source=helpers.sh
. "$(dirname "$RUNNER")/risk/helpers.sh"

budget_ms() {
  case $OSTYPE in
    darwin*) echo 2000 ;;
    msys* | cygwin*) echo 5000 ;;
    *) echo 1000 ;;
  esac
}

# now_ms: wall clock in milliseconds; date +%N is GNU only, perl is on every macOS.
now_ms() {
  local ns
  ns=$(date +%s%N)
  case $ns in
    *N) perl -MTime::HiRes=time -e 'printf "%d\n", time * 1000' ;;
    *) echo $((ns / 1000000)) ;;
  esac
}

# timed_risk REPO ARGS...: run the classifier, keeping its output in $out, $rc and the
# best of three wall times in $ms, so one scheduling hiccup does not fail the budget.
timed_risk() {
  local start end t
  ms=''
  for _ in 1 2 3; do
    start=$(now_ms)
    risk "$@"
    end=$(now_ms)
    t=$((end - start))
    if [ -z "$ms" ] || [ "$t" -lt "$ms" ]; then ms=$t; fi
  done
}

# assert_budget LIMIT_MS WHAT REPO ARGS...: $ms is under LIMIT_MS; otherwise print where
# one more run spends its time (bash 5 only: EPOCHREALTIME), slowest steps first.
assert_budget() {
  local limit=$1 what=$2 root start
  shift 2
  echo "$what: ${ms} ms (budget $limit ms)"
  [ "$ms" -ge "$limit" ] || return 0
  root=$(dirname "$(dirname "$RUNNER")")
  if [ -n "${EPOCHREALTIME:-}" ]; then
    # shellcheck disable=SC2016
    PS4='+ $EPOCHREALTIME ' bash -x "$root/plugins/overdrive/libexec/overdrive-risk" --repo "$@" 2>&1 >/dev/null |
      awk '/^\++ [0-9]/ { t = $2 + 0; if (p) printf "%6.0f ms  %s\n", (t - p) * 1000, substr(prev, 1, 100); p = t; prev = $0 }' |
      sort -rn | head -n 15
  fi
  # How much of it is git reading the change, which the classifier cannot do without.
  start=$(now_ms)
  case $2 in
    --diff) git -C "$1" diff -U0 "$3" >/dev/null ;;
    *)
      git -C "$1" diff -U0 HEAD >/dev/null
      git -C "$1" ls-files -o -z --exclude-standard | (cd "$1" && xargs -0 cat) >/dev/null
      ;;
  esac
  echo "git reading the same change: $(($(now_ms) - start)) ms"
  return 1
}

# write_files DIR COUNT LINES: COUNT source files of LINES lines each, plus one test per
# ten files, written by a single awk process.
write_files() {
  awk -v dir="$1" -v count="$2" -v lines="$3" -v tag="${4:-}" 'BEGIN {
    for (f = 1; f <= count; f++) {
      p = sprintf("%s/mod%04d.ts", dir, f)
      for (l = 1; l <= lines; l++) printf "export const v%d_%d = \"%s line %d of a module\";\n", f, l, tag, l > p
      close(p)
      if (f % 10 == 0) {
        t = sprintf("%s/mod%04d.test.ts", dir, f)
        printf "test(\"m%d\", () => {});\n", f > t
        close(t)
      }
    }
  }'
}

test_large_diff_under_one_second() {
  local repo
  repo=$(make_repo)
  write_file "$repo" .overdrive/risk-map.conf 'keyword cobro money
symbol computeScore scoring
content "stripe\.charges\.create" money'
  mkdir -p "$repo/src/billing" "$repo/src/lib"
  write_files "$repo/src/lib" 1000 10 old
  commit_all "$repo" base
  write_files "$repo/src/lib" 1000 10 new
  printf 'const m = new Mutex();\n' >> "$repo/src/lib/mod0500.ts"
  commit_all "$repo" change
  timed_risk "$repo" --diff HEAD~1..HEAD
  assert_eq 0 "$rc" "exit code: $(cat err)"
  assert_line "$out" "item concurrency critical floor line src/lib/mod0500.ts:11"
  assert_budget "$(budget_ms)" "diff of 10,000 changed lines in 1,000 files" "$repo" --diff HEAD~1..HEAD

  # New files the working tree has not added yet are read as well: every one is opened
  # from disk, which on Windows costs more than the whole classification, so this check
  # has twice the budget.
  git -C "$repo" reset -q --hard HEAD~1
  mkdir -p "$repo/src/fresh"
  write_files "$repo/src/fresh" 1000 10 new
  printf 'const m = new Mutex();\n' >> "$repo/src/fresh/mod0500.ts"
  timed_risk "$repo" --worktree
  assert_eq 0 "$rc" "exit code: $(cat err)"
  assert_line "$out" "item concurrency critical floor line src/fresh/mod0500.ts:11"
  assert_budget "$(($(budget_ms) * 2))" "worktree with 1,100 untracked files" "$repo" --worktree
}

test_many_files_stay_within_twice_the_budget() {
  local repo
  repo=$(make_repo)
  mkdir -p "$repo/src/api"
  write_files "$repo/src/api" 10000 1 old
  commit_all "$repo" base
  write_files "$repo/src/api" 10000 1 new
  commit_all "$repo" change
  timed_risk "$repo" --diff HEAD~1..HEAD
  assert_eq 0 "$rc" "exit code: $(cat err)"
  assert_line "$out" "item public-contract critical floor path src/api/mod0001.ts"
  assert_budget "$(($(budget_ms) * 2))" "diff of 10,000 changed files" "$repo" --diff HEAD~1..HEAD
}
