#!/usr/bin/env bash
# Tests for overdrive ledger.

od() { "$BASH" "$(dirname "$(dirname "$RUNNER")")/plugins/overdrive/bin/overdrive" "$@"; }

sq() {
  local s=$1 slash=/
  s=${s//$slash$slash/$slash}
  printf '%s' "$s"
}

# plan_repo: a repo with a three-task plan at "docs/plans/cart plan.md".
plan_repo() {
  local repo
  repo=$(make_repo)
  write_file "$repo" "docs/plans/cart plan.md" '# Cart plan

### Task 1: Totals
### Task 2: Discounts
## Task 3: Taxes
Task 4 is mentioned in prose, not a heading.'
  printf '%s\n' "$repo"
}

test_init_is_idempotent() {
  local repo out again ledger plan_abs
  repo=$(plan_repo)
  out=$(cd "$repo/docs" && od ledger init --plan "plans/cart plan.md")
  plan_abs="$(cd "$repo/docs/plans" && pwd -P)/cart plan.md"
  # The plan directory is the sanitized stem plus the checksum of the absolute path.
  ledger=$(sq "$repo")/.overdrive/run/cart-plan-$(printf %s "$plan_abs" | cksum | cut -d' ' -f1)/ledger.md
  assert_eq "$ledger" "$out"
  assert_eq "# Overdrive ledger — plan: $plan_abs" "$(sed -n 1p "$ledger")"
  assert_eq "Run: branch $(git -C "$repo" symbolic-ref --short HEAD)" "$(sed -n 2p "$ledger")"
  (cd "$repo" && od ledger add 'Task 1: in-progress') >/dev/null
  again=$(cd "$repo" && od ledger init --plan "docs/plans/cart plan.md")
  assert_eq "$ledger" "$again"
  assert_eq 'Task 1: in-progress' "$(sed -n 3p "$ledger")"
  assert_eq 3 "$(wc -l < "$ledger" | tr -d ' ')"
  assert_eq "$ledger" "$(cd "$repo" && od ledger path)"
}

test_init_refuses_foreign_plan() {
  local repo rc=0 ledger other
  repo=$(plan_repo)
  write_file "$repo" "other/cart plan.md" '### Task 1: Something else'
  ledger=$(cd "$repo" && od ledger init --plan "docs/plans/cart plan.md")
  # Same stem, different plan: a separate ledger, never a shared one.
  other=$(cd "$repo" && od ledger init --plan "other/cart plan.md")
  [ "$ledger" != "$other" ]
  assert_file_contains "$other" 'other/cart plan\.md$'
  # A ledger whose header names another plan is refused, not adopted.
  printf '# Overdrive ledger — plan: /elsewhere/cart plan.md\n' > "$ledger"
  (cd "$repo" && od ledger init --plan "docs/plans/cart plan.md") >/dev/null 2>&1 || rc=$?
  assert_eq 65 "$rc"
  rc=0
  (cd "$repo" && od ledger add --plan "docs/plans/cart plan.md" 'Note: x') >/dev/null 2>&1 || rc=$?
  assert_eq 65 "$rc"
  rc=0
  (cd "$repo" && od ledger init --plan nosuch.md) >/dev/null 2>&1 || rc=$?
  assert_eq 66 "$rc"
}

test_plan_names_never_collide_with_run_files() {
  local repo run name ledger
  repo=$(plan_repo)
  run=$repo/.overdrive/run
  (cd "$repo" && od pin --status) >/dev/null
  for name in pins active-ledger evidence reviews '.hidden' 'a b/c' 'páginas legales'; do
    write_file "$repo" "plans/$name.md" '### Task 1: X'
    ledger=$(cd "$repo" && od ledger init --plan "plans/$name.md")
    case ${ledger#"$(sq "$run")"/} in
      [A-Za-z0-9._-]*-[0-9]*/ledger.md) ;;
      *) echo "unexpected ledger path: $ledger" >&2; return 1 ;;
    esac
    case ${ledger#"$(sq "$run")"/} in */*/*) echo "nested: $ledger" >&2; return 1 ;; esac
  done
  [ -f "$run/active-ledger" ]
  [ ! -e "$run/pins" ]
  [ ! -e "$run/evidence" ] || [ -z "$(ls "$run/evidence")" ]
}

test_add_rejects_free_text() {
  local repo ledger line rc
  repo=$(plan_repo)
  ledger=$(cd "$repo" && od ledger init --plan "docs/plans/cart plan.md")
  for line in 'did some work' 'Task 1: done' 'Task 1: completed' 'Task x: complete' \
    'Task 1: fixing round' 'Note:' 'Note: ' 'Preflight:' "Note: two
lines" 'task 1: complete'; do
    rc=0; (cd "$repo" && od ledger add "$line") >/dev/null 2>&1 || rc=$?
    assert_eq 65 "$rc" "$line"
  done
  for line in 'Task 1: in-progress' 'Task 1: fixing round 2' 'Task 12: complete — 3f2a1bc' \
    'Note: resumed after a restart' 'Preflight: no produces/consumes conflicts' 'Task 2: blocked'; do
    (cd "$repo" && od ledger add "$line") >/dev/null
  done
  assert_eq 8 "$(wc -l < "$ledger" | tr -d ' ')"
}

test_ruling_requires_three_parts() {
  local repo ledger line rc
  repo=$(plan_repo)
  ledger=$(cd "$repo" && od ledger init --plan "docs/plans/cart plan.md")
  for line in 'Ruling: use a lock' 'Ruling: use a lock — appends race' \
    'Ruling: use a lock — appends race — ' 'Ruling:  — appends race — lost lines' \
    'Ruling: a — b — c — d' 'Ruling: use a lock - appends race - lost lines'; do
    rc=0; (cd "$repo" && od ledger add "$line") >/dev/null 2>&1 || rc=$?
    assert_eq 65 "$rc" "$line"
  done
  (cd "$repo" && od ledger add 'Ruling: use a lock — appends race on Windows — a lost line') >/dev/null
  (cd "$repo" && od ledger add 'Note: unrelated') >/dev/null
  assert_eq 'Ruling: use a lock — appends race on Windows — a lost line' "$(cd "$repo" && od ledger rulings)"
}

test_status_next_task() {
  local repo out
  repo=$(plan_repo)
  (cd "$repo" && od ledger init --plan "docs/plans/cart plan.md") >/dev/null
  out=$(cd "$repo" && od ledger status)
  assert_eq 'Task 1: pending
Task 2: pending
Task 3: pending
next 1' "$out"
  for line in 'Task 1: in-progress' 'Task 1: complete' 'Task 2: reviewing' \
    'Task 2: fixing round 1' 'Note: Task 3: complete is not a state line' 'Task 3: complete — early'; do
    (cd "$repo" && od ledger add "$line") >/dev/null
  done
  out=$(cd "$repo" && od ledger status)
  assert_eq 'Task 1: complete
Task 2: fixing round 1
Task 3: complete
next 2' "$out"
  (cd "$repo" && od ledger add 'Task 2: complete') >/dev/null
  # A task the plan does not list still counts once it is in the ledger.
  (cd "$repo" && od ledger add 'Task 10: blocked') >/dev/null
  out=$(cd "$repo" && od ledger status)
  assert_line "$out" 'Task 10: blocked'
  assert_line "$out" 'next 10'
  (cd "$repo" && od ledger add 'Task 10: complete') >/dev/null
  assert_line "$(cd "$repo" && od ledger status)" 'next none'
}

test_active_ledger_and_explicit_plan() {
  local repo a b rc=0
  repo=$(plan_repo)
  write_file "$repo" docs/plans/second.md '### Task 1: Other'
  a=$(cd "$repo" && od ledger init --plan "docs/plans/cart plan.md")
  b=$(cd "$repo" && od ledger init --plan docs/plans/second.md)
  assert_eq "$b" "$(cd "$repo" && od ledger path)"
  (cd "$repo" && od ledger add --plan "docs/plans/cart plan.md" 'Task 2: in-progress') >/dev/null
  assert_eq 'Task 2: in-progress' "$(sed -n '$p' "$a")"
  assert_eq "$a" "$(cd "$repo" && od ledger path --plan "docs/plans/cart plan.md")"
  # Re-initializing an existing ledger makes it the active one again (resume).
  (cd "$repo" && od ledger init --plan "docs/plans/cart plan.md") >/dev/null
  assert_eq "$a" "$(cd "$repo" && od ledger path)"
  rm "$repo/.overdrive/run/active-ledger"
  (cd "$repo" && od ledger status) >/dev/null 2>&1 || rc=$?
  assert_eq 66 "$rc"
}

test_parallel_appends_keep_every_line() {
  local repo ledger i od_bin
  repo=$(plan_repo)
  ledger=$(cd "$repo" && od ledger init --plan "docs/plans/cart plan.md")
  # Waiters on a loaded machine must not give up before the holders finish.
  export OD_LOCK_TIMEOUT=60
  od_bin=$(dirname "$(dirname "$RUNNER")")/plugins/overdrive/bin/overdrive
  # Separate processes with their own pids, as parallel builders would be.
  for i in $(seq 1 20); do
    # shellcheck disable=SC2016
    (cd "$repo" && "$BASH" -c '"$BASH" "$1" ledger add "Note: writer $2 reporting a long enough line to expose torn writes"' _ "$od_bin" "$i") > "out$i" 2>&1 &
  done
  wait
  for i in $(seq 1 20); do
    [ ! -s "out$i" ] || { cat "out$i" >&2; return 1; }
  done
  assert_eq 22 "$(wc -l < "$ledger" | tr -d ' ')"
  for i in $(seq 1 20); do
    assert_eq 1 "$(grep -cx "Note: writer $i reporting a long enough line to expose torn writes" "$ledger")" "writer $i"
  done
}

test_unreviewed_lists_critical_tasks_without_a_review_after_their_last_change() {
  local repo line
  repo=$(plan_repo)
  (cd "$repo" && od ledger init --plan "docs/plans/cart plan.md") >/dev/null
  for line in 'Task 3: pending' 'Task 2: in-progress critical' 'Task 2: implemented' 'Task 2: reviewing' \
    'Task 2: fixing round 1' 'Task 1: in-progress critical' 'Task 1: implemented' 'Task 1: reviewing' 'Task 1: complete'; do
    (cd "$repo" && od ledger add "$line") >/dev/null
  done
  assert_eq 2 "$(cd "$repo" && od ledger unreviewed)"
  (cd "$repo" && od ledger add 'Task 2: reviewing') >/dev/null
  assert_eq '' "$(cd "$repo" && od ledger unreviewed)"
}

test_unreviewed_ignores_unmarked_and_blocked_tasks() {
  local repo line
  repo=$(plan_repo)
  (cd "$repo" && od ledger init --plan "docs/plans/cart plan.md") >/dev/null
  for line in 'Task 1: in-progress critical' 'Task 1: implemented' 'Task 1: reviewing' 'Task 1: complete' \
    'Task 2: in-progress' 'Task 2: implemented' 'Task 2: complete' 'Task 3: blocked sudo apt install libfoo'; do
    (cd "$repo" && od ledger add "$line") >/dev/null
  done
  assert_eq '' "$(cd "$repo" && od ledger unreviewed)"
  assert_eq '' "$(cd "$repo" && od ledger unreviewed --all-started)"
  # Blocked after work started stays gated; so does an unmarked task still open.
  (cd "$repo" && od ledger add 'Task 3: in-progress critical' && od ledger add 'Task 3: blocked sudo') >/dev/null
  assert_eq 3 "$(cd "$repo" && od ledger unreviewed)"
}

test_unreviewed_all_started_lists_unmarked_open_tasks() {
  local repo
  repo=$(plan_repo)
  (cd "$repo" && od ledger init --plan "docs/plans/cart plan.md") >/dev/null
  for line in 'Task 1: in-progress' 'Task 1: fixing round 1 done' 'Task 2: implemented' 'Task 3: in-progress' 'Task 3: complete'; do
    (cd "$repo" && od ledger add "$line") >/dev/null
  done
  assert_eq '' "$(cd "$repo" && od ledger unreviewed)"
  assert_eq "1
2" "$(cd "$repo" && od ledger unreviewed --all-started)"
}

test_unreviewed_treats_a_finished_ledger_as_done() {
  local repo
  repo=$(plan_repo)
  (cd "$repo" && od ledger init --plan "docs/plans/cart plan.md") >/dev/null
  for line in 'Task 1: in-progress critical' 'Task 1: implemented' 'Task 1: complete'; do
    (cd "$repo" && od ledger add "$line") >/dev/null
  done
  assert_eq '' "$(cd "$repo" && od ledger unreviewed --all-started)"
}

test_unreviewed_applies_only_on_the_runs_branch() {
  local repo
  repo=$(plan_repo)
  (cd "$repo" && od ledger init --plan "docs/plans/cart plan.md" && od ledger add 'Task 1: in-progress critical') >/dev/null
  assert_eq 1 "$(cd "$repo" && od ledger unreviewed)"
  git -C "$repo" checkout -q -b elsewhere
  assert_eq '' "$(cd "$repo" && od ledger unreviewed --all-started)"
  git -C "$repo" checkout -q -
  assert_eq 1 "$(cd "$repo" && od ledger unreviewed)"
}

test_unreviewed_without_a_ledger_fails_like_the_other_readers() {
  local repo rc=0
  repo=$(make_repo)
  (cd "$repo" && od ledger unreviewed) >/dev/null 2>&1 || rc=$?
  assert_eq 66 "$rc"
}
