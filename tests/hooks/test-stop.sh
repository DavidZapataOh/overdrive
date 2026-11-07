#!/usr/bin/env bash
# Tests for plugins/overdrive/hooks/stop.

plugin_dir() { printf '%s\n' "$(dirname "$(dirname "$RUNNER")")/plugins/overdrive"; }

jstr() {
  # shellcheck source=../../plugins/overdrive/lib/json.sh
  . "$(plugin_dir)/lib/json.sh"
  json_escape "$1"
}

# stop_event MESSAGE [CWD] [SID] [ACTIVE]: a Stop event as Claude Code sends it.
stop_event() {
  printf '{"session_id":"%s","transcript_path":"/t.jsonl","cwd":"%s","permission_mode":"default","hook_event_name":"Stop","stop_hook_active":%s,"last_assistant_message":"%s","background_tasks":[],"session_crons":[]}' \
    "$(jstr "${3:-sess-1}")" "$(jstr "${2:-$PWD}")" "${4:-false}" "$(jstr "$1")"
}

# stop EVENT: run the hook as Claude Code does, with a project dir that must not matter.
stop() {
  printf '%s' "$1" | CLAUDE_PLUGIN_ROOT="$(plugin_dir)" CLAUDE_PROJECT_DIR=/nonexistent "$(plugin_dir)/hooks/stop"
}

assert_allows() {
  local out rc=0
  out=$(stop "$1") || rc=$?
  assert_eq 0 "$rc" "exit code"
  assert_eq '' "$out" "stdout of an allowed stop"
}

# assert_blocks EVENT REASON: exit 0 with a block decision whose reason is exactly REASON
# (or contains it, with a third argument).
assert_blocks() {
  local out rc=0
  out=$(stop "$1") || rc=$?
  assert_eq 0 "$rc" "exit code"
  case $out in
    '{"decision":"block","reason":"'*'"}') ;;
    *) printf 'not a block: %s\n' "$out" >&2; return 1 ;;
  esac
  # shellcheck source=../../plugins/overdrive/lib/json.sh
  . "$(plugin_dir)/lib/json.sh"
  json_extract_string reason "$out"
  if [ -n "${3-}" ]; then
    case $JSON_VALUE in
      *"$2"*) ;;
      *) printf 'reason lacks: %s\n  got: %s\n' "$2" "$JSON_VALUE" >&2; return 1 ;;
    esac
  else
    assert_eq "$2" "$JSON_VALUE" "reason"
  fi
  if command -v python3 >/dev/null 2>&1; then
    printf '%s' "$out" | python3 -m json.tool >/dev/null
  fi
}

MISSING='Close this change with its Risk line: run overdrive risk --worktree (or --diff <base>...HEAD) and end with the Risk line it prints.'

# lower_reason STATED CLASSIFIED ITEMS
lower_reason() {
  printf 'Risk line says %s but the diff classifies as %s (%s). Raise the lane, or cite the user'"'"'s explicit decision as "(lowered by user, D-NNNN)".' "$1" "$2" "$3"
}

# mark REPO [SID]: what the PreToolUse hook leaves after an edit in REPO.
mark() {
  mkdir -p "$1/.overdrive/run/markers"
  printf '*\n' > "$1/.overdrive/run/.gitignore"
  : > "$1/.overdrive/run/markers/${2:-sess-1}.changed"
}

marked() { [ -f "$1/.overdrive/run/markers/${2:-sess-1}.changed" ]; }

# main_repo: a repo on main with origin/main and origin/HEAD, as a clone has.
main_repo() {
  local repo
  repo=$(make_repo)
  git -C "$repo" branch -q -M main
  git -C "$repo" update-ref refs/remotes/origin/main HEAD
  git -C "$repo" symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main
  printf '%s\n' "$repo"
}

# pushed REPO: origin/main catches up with HEAD, as after a push.
pushed() { git -C "$1" update-ref refs/remotes/origin/main HEAD; }

# auth_change REPO: an uncommitted change the classifier puts in the critical lane.
auth_change() { write_file "$1" src/auth/session.ts 'export const ttl = 1'; }

# deps_change REPO: an uncommitted change the classifier puts in the standard lane.
deps_change() {
  commit_file "$1" package.json '{"dependencies":{}}'
  pushed "$1"
  write_file "$1" package.json '{"dependencies":{"left-pad":"1.3.0"}}'
}

# decisions REPO: D-0001 active, D-0002 superseded by D-0003.
decisions() {
  write_file "$1" .overdrive/decisions.md '# Decisions

## D-0001 — Ship the session TTL as direct

- Date: 2026-11-07
- Scope: src/auth
- Decision: The TTL constant change goes in the direct lane.
- Source: "lower it, it is a constant" — founder, 2026-11-07
- Why: A constant covered by an existing test.
- Cost if wrong: A wrong TTL ships without review.
- Status: active

## D-0002 — Ship auth tweaks as standard

- Date: 2026-11-01
- Scope: src/auth
- Decision: Auth tweaks go in the standard lane.
- Source: "fine" — founder, 2026-11-01
- Why: Small changes.
- Cost if wrong: Auth bugs.
- Status: superseded by D-0003

## D-0003 — Auth changes stay critical

- Date: 2026-11-02
- Scope: src/auth
- Decision: Auth changes stay critical.
- Source: Ruling — builder, 2026-11-02
- Why: Floors.
- Cost if wrong: Slower auth work.
- Status: active'
}

test_stop_noop_without_marker() {
  local repo
  repo=$(main_repo)
  auth_change "$repo"
  # A turn that changed nothing in this session: other sessions' markers do not count.
  mark "$repo" other-session
  assert_allows "$(stop_event 'Here is how the session cookie works.' "$repo")"
  assert_allows "$(stop_event 'Done.' "$repo/src/auth")"
}

test_stop_noop_when_edits_outside_git() {
  local plain
  # The session started above any repository and only touched plain folders.
  mkdir -p plain/notes plain/fake/.overdrive/run/markers
  plain=$PWD/plain
  printf 'x\n' > plain/notes/a.md
  # A marker in a folder that is not a repository is not this hook's business.
  : > plain/fake/.overdrive/run/markers/sess-1.changed
  GIT_CEILING_DIRECTORIES=$PWD assert_allows "$(stop_event 'Edited the notes.' "$plain")"
  assert_allows "$(stop_event 'Edited the notes.' "$plain/notes")"
  [ ! -e plain/.overdrive ] || { echo "created state outside git" >&2; return 1; }
}

test_blocks_missing_risk_line() {
  local repo top
  repo=$(main_repo)
  auth_change "$repo"
  mark "$repo"
  assert_blocks "$(stop_event 'Done: the TTL is shorter.' "$repo")" "$MISSING"
  # Near misses are not the Risk line.
  assert_blocks "$(stop_event 'Risk: low — none' "$repo")" "$MISSING"
  # shellcheck disable=SC2016
  assert_blocks "$(stop_event '`Risk: critical — auth`' "$repo")" "$MISSING"
  assert_blocks "$(stop_event 'Risk: critical - auth' "$repo")" "$MISSING"
  assert_blocks "$(stop_event 'Done. Risk: critical — auth' "$repo")" "$MISSING"
  # The session started in a plain folder above the repository it changed.
  top=$PWD/top
  mkdir -p "$top"
  mv "$repo" "$top/my repo"
  assert_blocks "$(stop_event 'Done.' "$top")" "$MISSING"
  assert_blocks "$(stop_event 'Done.' "$top/my repo/src")" "$MISSING"
  marked "$top/my repo" || { echo "marker removed on a block" >&2; return 1; }
}

test_blocks_lower_lane_than_classifier() {
  local repo
  repo=$(main_repo)
  auth_change "$repo"
  mark "$repo"
  assert_blocks "$(stop_event 'Done.
Risk: standard — none' "$repo")" "$(lower_reason standard critical 'auth, untested-change')"
  assert_blocks "$(stop_event 'Risk: direct — none' "$repo")" "$(lower_reason direct critical 'auth, untested-change')"
  marked "$repo" || { echo "marker removed on a block" >&2; return 1; }
  # Committed on a branch: the worktree is clean but the branch is not.
  git -C "$repo" checkout -q -b feature
  git -C "$repo" add -A
  git -C "$repo" commit -q -m 'shorter ttl'
  assert_blocks "$(stop_event 'Risk: direct — none' "$repo")" "$(lower_reason direct critical 'auth, untested-change')"
  # Unpushed commits on the default branch are part of the change too.
  git -C "$repo" checkout -q main
  git -C "$repo" merge -q --ff-only feature
  assert_blocks "$(stop_event 'Risk: direct — none' "$repo")" "$(lower_reason direct critical 'auth, untested-change')"
}

test_allows_equal_or_higher_lane() {
  local repo
  repo=$(main_repo)
  deps_change "$repo"
  mark "$repo"
  assert_allows "$(stop_event 'Bumped left-pad.
Risk: standard — dependencies' "$repo")"
  mark "$repo"
  assert_allows "$(stop_event 'Risk: critical — dependencies' "$repo")"
  # With several lines, the highest one counts; CRLF endings are tolerated.
  auth_change "$repo"
  mark "$repo"
  assert_allows "$(stop_event "Risk: direct — none"$'\r\n'"Risk: critical — auth, untested-change"$'\r' "$repo")"
}

test_allows_user_lowering_with_active_decision() {
  local repo
  repo=$(main_repo)
  decisions "$repo"
  git -C "$repo" add -A
  git -C "$repo" commit -q -m decisions
  pushed "$repo"
  auth_change "$repo"
  mark "$repo"
  assert_allows "$(stop_event 'TTL shortened.
Risk: direct — none (lowered by user, D-0001)' "$repo")"
  marked "$repo" && { echo "marker kept after a pass" >&2; return 1; }
  return 0
}

test_rejects_lowering_with_superseded_decision() {
  local repo
  repo=$(main_repo)
  decisions "$repo"
  auth_change "$repo"
  mark "$repo"
  assert_blocks "$(stop_event 'Risk: standard — auth (lowered by user, D-0002)' "$repo")" \
    "$(lower_reason standard critical 'auth, untested-change') D-0002 is not an active decision in .overdrive/decisions.md."
  # An id that does not exist, or a malformed one, is no decision either.
  assert_blocks "$(stop_event 'Risk: direct — none (lowered by user, D-0099)' "$repo")" \
    'D-0099 is not an active decision' contains
  assert_blocks "$(stop_event 'Risk: direct — none (lowered by user, D-1)' "$repo")" \
    "$(lower_reason direct critical 'auth, untested-change')"
  # A decision in another repository does not lower this one.
  rm "$repo/.overdrive/decisions.md"
  assert_blocks "$(stop_event 'Risk: direct — none (lowered by user, D-0001)' "$repo")" \
    'D-0001 is not an active decision' contains
  marked "$repo" || { echo "marker removed on a block" >&2; return 1; }
}

test_respects_stop_hook_active() {
  local repo
  repo=$(main_repo)
  auth_change "$repo"
  mark "$repo"
  # Already continuing because of a stop hook: never block again.
  assert_allows "$(stop_event 'Done.' "$repo" sess-1 true)"
  assert_allows "$(stop_event 'Risk: direct — none' "$repo" sess-1 true)"
  marked "$repo" || { echo "marker removed without a valid Risk line" >&2; return 1; }
  # A continuation that fixed the line closes the change, so the next turn is free.
  assert_allows "$(stop_event 'Risk: critical — auth, untested-change' "$repo" sess-1 true)"
  marked "$repo" && { echo "marker kept after a fixed line" >&2; return 1; }
  return 0
}

test_clears_marker_on_pass() {
  local repo other
  repo=$(main_repo)
  auth_change "$repo"
  mark "$repo"
  mark "$repo" sess-2
  assert_allows "$(stop_event 'Risk: critical — auth, untested-change' "$repo")"
  marked "$repo" && { echo "marker kept after a pass" >&2; return 1; }
  marked "$repo" sess-2 || { echo "another session's marker removed" >&2; return 1; }
  # The next turn, a question, closes freely.
  assert_allows "$(stop_event 'The TTL lives in src/auth.' "$repo")"
  # Every repository the session changed is checked, each against its own classification.
  mkdir top
  mv "$repo" top/a
  other=$(main_repo)
  mv "$other" top/b
  deps_change top/b
  mark top/a
  mark top/b
  assert_blocks "$(stop_event 'Risk: standard — dependencies' "$PWD/top")" \
    "$PWD/top/a: $(lower_reason standard critical 'auth, untested-change')"
  marked top/a || { echo "failing repo's marker removed" >&2; return 1; }
  marked top/b && { echo "passing repo's marker kept" >&2; return 1; }
  mark top/b
  assert_allows "$(stop_event 'Risk: critical — auth, untested-change' "$PWD/top")"
  if marked top/a || marked top/b; then echo "markers kept after a pass" >&2; return 1; fi
}

test_classification_failure_counts_as_critical() {
  local repo
  # No commits yet: nothing to compare against, so the classifier fails closed.
  repo=$PWD/unborn
  git init -q "$repo"
  write_file "$repo" README.md 'hello'
  mark "$repo"
  assert_blocks "$(stop_event 'Risk: direct — none' "$repo")" \
    "$(lower_reason direct critical classification-failed) The classifier failed: no commits yet."
  assert_allows "$(stop_event 'Risk: critical — classification-failed' "$repo")"
}

test_broken_install_never_traps_the_session() {
  local repo copy out rc=0
  repo=$(main_repo)
  auth_change "$repo"
  mark "$repo"
  copy=$PWD/plugin
  cp -R "$(plugin_dir)" "$copy"
  rm "$copy/lib/json.sh"
  out=$(stop_event 'Done.' "$repo" | CLAUDE_PLUGIN_ROOT=$copy "$copy/hooks/stop") || rc=$?
  assert_eq 0 "$rc" "exit code"
  case $out in '' | '{"systemMessage":'*) ;; *) echo "unexpected output: $out" >&2; return 1 ;; esac
  # Input it cannot read, or a Claude Code without the closing message, lets the stop through.
  assert_allows 'not json'
  assert_allows "{\"session_id\":\"sess-1\",\"cwd\":\"$(jstr "$repo")\",\"hook_event_name\":\"Stop\",\"stop_hook_active\":false}"
}

test_registered_with_a_timeout() {
  local hooks
  hooks=$(cat "$(plugin_dir)/hooks/hooks.json")
  # shellcheck disable=SC2016
  case $hooks in
    *'"Stop": ['*'"command": "\"${CLAUDE_PLUGIN_ROOT}/hooks/stop\""'*'"timeout": '[0-9]*) ;;
    *) echo "Stop hook not registered with a timeout" >&2; return 1 ;;
  esac
}

test_latency_under_400ms_with_classifier() {
  local repo i t0 t1 best='' root event
  # A shared developer machine is too noisy for a wall-clock budget.
  if [ -z "${CI:-}" ] || [ "$(uname -s)" != Linux ]; then
    echo "notice: latency budget is asserted on Linux CI only; skipped"
    return 0
  fi
  if [ -z "${EPOCHREALTIME:-}" ]; then
    echo "notice: bash $BASH_VERSION has no EPOCHREALTIME; latency skipped"
    return 0
  fi
  repo=$(main_repo)
  mkdir -p "$repo/src" "$repo/tests"
  for i in $(seq 1000); do
    printf 'export const v%d = %d\n' "$i" "$i" > "$repo/src/m$i.ts"
  done
  printf 'test\n' > "$repo/tests/m.test.ts"
  git -C "$repo" add -A
  git -C "$repo" commit -q -m 'a thousand modules'
  git -C "$repo" update-ref refs/remotes/origin/main HEAD
  # A branch that changed every file: half committed, half still in the worktree.
  git -C "$repo" checkout -q -b feature
  for i in $(seq 500); do printf 'export const v%d = 0\n' "$i" > "$repo/src/m$i.ts"; done
  git -C "$repo" commit -qam 'zero the first half'
  for i in $(seq 501 1000); do printf 'export const v%d = 0\n' "$i" > "$repo/src/m$i.ts"; done
  root=$(plugin_dir)
  event=$(stop_event 'Risk: critical — untested-change' "$repo")
  for i in 1 2 3 4 5; do
    mark "$repo"
    t0=${EPOCHREALTIME/[.,]/}
    CLAUDE_PLUGIN_ROOT=$root "$root/hooks/stop" <<<"$event" >/dev/null
    t1=${EPOCHREALTIME/[.,]/}
    echo "run $i: $((t1 - t0)) us" >&2
    if [ -z "$best" ] || [ $((t1 - t0)) -lt "$best" ]; then best=$((t1 - t0)); fi
  done
  marked "$repo" && { echo "the classified stop did not pass" >&2; return 1; }
  [ "$best" -lt 400000 ] || { echo "best ${best} us over 400 ms" >&2; return 1; }
}
