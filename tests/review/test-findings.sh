#!/usr/bin/env bash
# Tests for overdrive findings.

od() { "$BASH" "$(dirname "$(dirname "$RUNNER")")/plugins/overdrive/bin/overdrive" "$@"; }

# code_repo: a repo whose HEAD holds a ten-line file with a space in its path.
code_repo() {
  local repo
  repo=$(make_repo)
  write_file "$repo" "src/pay ment.ts" 'line 1
line 2
line 3
line 4
line 5
line 6
if (a || b) { charge("x\y"); }
line 8
line 9
line 10'
  stage_all "$repo"
  git -C "$repo" commit -q -m code
  printf '%s\n' "$repo"
}

test_findings_rejects_unanchored_confidence() {
  local repo out rc=0
  repo=$(code_repo)
  printf '%s\n' 'F1 | P2 | 60 | - | Vague | "" | none | none | plan-mandated:no' > "$repo/f.md"
  out=$(cd "$repo" && od findings check f.md) || rc=$?
  assert_eq 1 "$rc"
  case $out in *F1*confidence*60*) ;; *) echo "out: $out" >&2; return 1 ;; esac
  printf '%s\n' 'F1 | P2 | 50 | - | Vague | "" | none | none | plan-mandated:no' > "$repo/f.md"
  (cd "$repo" && od findings check f.md) >/dev/null
}

test_findings_75_requires_quote_found_in_tree() {
  local repo out rc
  repo=$(code_repo)
  # Line 7 holds the quote; 4..10 are within three lines of it.
  printf '%s\n' \
    'F1 | P1 | 75 | src/pay ment.ts:4 | Double charge | "if (a || b) { charge(\"x\\y\"); }" | charges twice | guard it | plan-mandated:no' \
    'F2 | P1 | 100 | ./src/pay ment.ts:10 | Same | "charge(" | x | y | plan-mandated:yes' > "$repo/f.md"
  (cd "$repo" && od findings check f.md) >/dev/null

  printf '%s\n' 'F1 | P1 | 75 | src/pay ment.ts:3 | Too far | "charge(" | x | y | plan-mandated:no' > "$repo/f.md"
  rc=0; out=$(cd "$repo" && od findings check f.md) || rc=$?
  assert_eq 1 "$rc"
  case $out in *F1*quote*) ;; *) echo "out: $out" >&2; return 1 ;; esac

  printf '%s\n' 'F1 | P1 | 100 | src/pay ment.ts:7 | Invented | "charge(y)" | x | y | plan-mandated:no' > "$repo/f.md"
  rc=0; (cd "$repo" && od findings check f.md) >/dev/null || rc=$?
  assert_eq 1 "$rc"

  for q in '""' '"  "' '-'; do
    printf 'F1 | P1 | 75 | src/pay ment.ts:7 | No quote | %s | x | y | plan-mandated:no\n' "$q" > "$repo/f.md"
    rc=0; (cd "$repo" && od findings check f.md) >/dev/null || rc=$?
    assert_eq 1 "$rc" "quote $q"
  done

  printf '%s\n' 'F1 | P1 | 100 | - | No place | "charge(" | x | y | plan-mandated:no' > "$repo/f.md"
  rc=0; (cd "$repo" && od findings check f.md) >/dev/null || rc=$?
  assert_eq 1 "$rc"

  printf '%s\n' 'F1 | P1 | 75 | src/missing.ts:1 | Gone | "x" | x | y | plan-mandated:no' > "$repo/f.md"
  rc=0; (cd "$repo" && od findings check f.md) >/dev/null || rc=$?
  assert_eq 1 "$rc"

  # The head commit is the truth: text that exists only in the working tree, staged
  # or not, does not count.
  printf 'line 1\nnew uncommitted text\n' >> "$repo/src/pay ment.ts"
  git -C "$repo" add -A
  printf '%s\n' 'F1 | P1 | 75 | src/pay ment.ts:11 | Fresh | "new uncommitted text" | x | y | plan-mandated:no' > "$repo/f.md"
  rc=0; (cd "$repo" && od findings check f.md) >/dev/null || rc=$?
  assert_eq 1 "$rc"
  git -C "$repo" commit -q -m more
  (cd "$repo" && od findings check f.md) >/dev/null
  # --head pins the tree that was reviewed.
  rc=0; (cd "$repo" && od findings check --head HEAD~1 f.md) >/dev/null || rc=$?
  assert_eq 1 "$rc"
}

test_findings_any_quote_is_checked() {
  local repo rc=0
  repo=$(code_repo)
  # Below 75 a quote is optional, but one that is given must be real.
  printf '%s\n' 'F1 | P0 | 50 | src/pay ment.ts:7 | Invented | "charge(y)" | x | y | plan-mandated:no' > "$repo/f.md"
  (cd "$repo" && od findings check f.md) >/dev/null || rc=$?
  assert_eq 1 "$rc"
  printf '%s\n' 'F1 | P0 | 50 | src/pay ment.ts:7 | Real | "charge(" | x | y | plan-mandated:no' > "$repo/f.md"
  (cd "$repo" && od findings check f.md) >/dev/null
}

test_findings_check_rejects_malformed_lines() {
  local repo rc
  repo=$(code_repo)
  for line in \
    'F1 | P1 | 50 | - | Too few fields | "" | x | plan-mandated:no' \
    'F1 | P4 | 50 | - | Bad severity | "" | x | y | plan-mandated:no' \
    'X1 | P1 | 50 | - | Bad id | "" | x | y | plan-mandated:no' \
    'F1 | P1 | 50 | - | Bad flag | "" | x | y | plan-mandated:maybe' \
    'F1 | P1 | 50 | - | Open quote | "abc | x | y | plan-mandated:no' \
    'F1 | P1 | 50 | src/a.ts:0 | Bad line | "" | x | y | plan-mandated:no' \
    'free text that is not a finding'; do
    printf '%s\n' "$line" > "$repo/f.md"
    rc=0; (cd "$repo" && od findings check f.md) >/dev/null 2>&1 || rc=$?
    assert_eq 1 "$rc" "$line"
  done
  # Blank lines and an empty file are fine: no findings.
  : > "$repo/f.md"
  (cd "$repo" && od findings check f.md) >/dev/null
  rc=0; (cd "$repo" && od findings check nosuchfile) >/dev/null 2>&1 || rc=$?
  assert_eq 66 "$rc"
}

test_findings_pipes_in_fields() {
  local repo out
  repo=$(code_repo)
  # A quoted field keeps | as text; elsewhere \| is a literal pipe.
  printf '%s\r\n' 'F1 | P0 | 75 | src/pay ment.ts:7 | a \| b is wrong | "(a || b)" | x | y | plan-mandated:no' > "$repo/f.md"
  (cd "$repo" && od findings check f.md) >/dev/null
  out=$(cd "$repo" && od findings merge f.md)
  assert_eq 'F1 | P0 | 75 | src/pay ment.ts:7 | a \| b is wrong | "(a || b)" | x | y | plan-mandated:no' "$out"
}

test_findings_merge_dedupes_and_sorts() {
  local out
  printf '%s\n' \
    'F1 | P2 | 75 | src/a.ts:3 | Missing check | "a" | x | y | plan-mandated:no' \
    'F2 | P1 | 100 | src/b.ts:9 | Leak | "b" | x | y | plan-mandated:no' \
    'F3 | P3 | 25 | src/c.ts:1 | Nit | "" | x | y | plan-mandated:no' \
    'F4 | P1 | 50 | src/d.ts:1 | Maybe | "" | x | y | plan-mandated:no' > one.md
  printf '%s\n' \
    'F1 | P1 | 75 | ./src/a.ts:3 | missing  CHECK | "a2" | x | y | plan-mandated:yes' \
    'F2 | P1 | 75 | src/e.ts:2 | Race | "e" | x | y | plan-mandated:no' \
    '' \
    'F3 | P0 | 0 | src/f.ts:2 | Wrong | "" | x | y | plan-mandated:no' > two.md
  out=$(od findings merge one.md two.md)
  assert_eq 'F1 | P1 | 100 | src/b.ts:9 | Leak | "b" | x | y | plan-mandated:no
F2 | P1 | 75 | ./src/a.ts:3 | missing  CHECK | "a2" | x | y | plan-mandated:yes
F3 | P1 | 75 | src/e.ts:2 | Race | "e" | x | y | plan-mandated:no' "$out"
}

test_findings_keeps_p0_at_50() {
  local out
  printf '%s\n' \
    'F1 | P0 | 50 | src/a.ts:1 | Possible data loss | "" | x | y | plan-mandated:no' \
    'F2 | P1 | 50 | src/b.ts:1 | Possible bug | "" | x | y | plan-mandated:no' \
    'F3 | P0 | 25 | src/c.ts:1 | Unlikely | "" | x | y | plan-mandated:no' > f.md
  out=$(od findings merge f.md)
  assert_eq 'F1 | P0 | 50 | src/a.ts:1 | Possible data loss | "" | x | y | plan-mandated:no' "$out"
}

test_findings_file_names_with_equals_sign() {
  local out
  printf '%s\n' 'F1 | P0 | 50 | src/a.ts:1 | Possible data loss | "" | x | y | plan-mandated:no' > 'round=1.md'
  out=$(od findings merge 'round=1.md')
  assert_eq 'F1 | P0 | 50 | src/a.ts:1 | Possible data loss | "" | x | y | plan-mandated:no' "$out"
  out=$(od findings check 'round=1.md')
  assert_eq ok "$out"
}

test_findings_merge_rejects_malformed_input() {
  local rc=0
  printf '%s\n' 'F1 | P1 | 60 | - | Bad | "" | x | y | plan-mandated:no' > f.md
  od findings merge f.md >/dev/null 2>&1 || rc=$?
  assert_eq 1 "$rc"
}
