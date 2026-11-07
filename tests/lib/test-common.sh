#!/usr/bin/env bash
# Tests for plugins/overdrive/lib/common.sh.

# TMPDIR may end in a slash; the library collapses repeated slashes.
sq() {
  local s=$1 slash=/
  s=${s//$slash$slash/$slash}
  printf '%s' "$s"
}

load_common() { . "$(dirname "$(dirname "$RUNNER")")/plugins/overdrive/lib/common.sh"; }

test_repo_root_from_nested_cwd_outside_project_dir() {
  load_common
  local repo
  repo=$(make_repo)
  mkdir -p "$repo/apps/web"
  local outside=$PWD/outside
  mkdir -p "$outside"
  local got
  got=$(cd "$repo/apps/web" && CLAUDE_PROJECT_DIR=$outside && export CLAUDE_PROJECT_DIR && od_repo_root)
  assert_eq "$(sq "$repo")" "$got"
  got=$(CLAUDE_PROJECT_DIR=$outside od_repo_root "$repo/apps/web")
  assert_eq "$(sq "$repo")" "$got"
}

test_repo_root_no_repo_returns_1() {
  load_common
  mkdir -p plain/sub
  # The sandbox lives under TMPDIR, outside any repository.
  assert_exit 1 od_repo_root "$PWD/plain/sub"
  local got
  got=$(od_repo_root "$PWD/plain/sub") || true
  assert_eq "" "$got"
}

test_repo_root_worktree_git_file() {
  load_common
  local repo wt
  repo=$(make_repo)
  wt=$repo-wt
  git -C "$repo" worktree add -q "$wt" -b side
  [ -f "$wt/.git" ]
  mkdir -p "$wt/deep/er"
  assert_eq "$(sq "$wt")" "$(od_repo_root "$wt/deep/er")"
}

test_repo_root_nearest_wins_and_nonexistent_dir() {
  load_common
  local repo
  repo=$(make_repo)
  mkdir -p "$repo/sub/inner"
  git init -q "$repo/sub/inner"
  assert_eq "$(sq "$repo/sub/inner")" "$(od_repo_root "$repo/sub/inner")"
  assert_eq "$(sq "$repo")" "$(od_repo_root "$repo/not/yet/created.ts")"
}

test_repo_root_relative_and_trailing_slash() {
  load_common
  local repo
  repo=$(make_repo)
  mkdir -p "$repo/a b"
  assert_eq "$(sq "$repo")" "$(od_repo_root "$repo/a b/")"
  assert_eq "$(sq "$repo")" "$(cd "$repo/a b" && od_repo_root ..)"
}

test_repo_root_normalizes_backslashes() {
  load_common
  local repo
  repo=$(make_repo)
  mkdir -p "$repo/x"
  local win=${repo//\//\\}\\x
  # Only meaningful where backslash paths resolve (Git Bash); elsewhere it must not crash.
  if [ -e "$win" ]; then
    assert_eq "$(sq "$repo")" "$(od_repo_root "$win")"
  else
    od_repo_root "$win" > /dev/null || true
  fi
}

test_run_dir_self_ignores() {
  load_common
  local repo run
  repo=$(make_repo)
  run=$(od_run_dir "$repo")
  assert_eq "$repo/.overdrive/run" "$run"
  [ -d "$run" ]
  assert_eq '*' "$(cat "$run/.gitignore")"
  printf x > "$run/state"
  assert_eq "" "$(git -C "$repo" status --porcelain)"
  assert_eq "$run" "$(od_run_dir "$repo")"
}

test_double_source_is_a_noop() {
  load_common
  od_marker=kept
  load_common
  assert_eq kept "$od_marker"
  [ "$(type -t od_die)" = function ]
}

test_die_prints_and_exits() {
  load_common
  local out rc=0
  out=$( (od_die "boom" 7) 2>&1 ) || rc=$?
  assert_eq 7 "$rc"
  assert_eq "overdrive: boom" "$out"
  rc=0
  (od_die "x") >/dev/null 2>&1 || rc=$?
  assert_eq 1 "$rc"
}

test_lock_excludes_and_unlocks() {
  load_common
  local lock=$PWD/l.lock
  od_lock "$lock"
  [ -f "$lock" ]
  OD_LOCK_TIMEOUT=1 od_lock "$lock" && return 1
  od_unlock "$lock"
  [ ! -e "$lock" ]
  od_lock "$lock"
  od_unlock "$lock"
}

test_lock_breaks_stale_lock() {
  load_common
  local lock=$PWD/s.lock dead
  bash -c 'echo $$' > "$lock"
  dead=$(cat "$lock")
  # The helper has exited, so its pid is dead.
  kill -0 "$dead" 2>/dev/null && return 1
  od_lock "$lock"
  assert_eq "$$" "$(cat "$lock")"
  od_unlock "$lock"
}

test_lock_respects_live_holder() {
  load_common
  local lock=$PWD/h.lock
  sleep 5 &
  local holder=$!
  printf '%s\n' "$holder" > "$lock"
  OD_LOCK_TIMEOUT=1 od_lock "$lock" && { kill "$holder"; return 1; }
  kill "$holder"
  wait "$holder" 2>/dev/null || true
  [ -f "$lock" ]
}

test_lock_creates_missing_parent() {
  load_common
  od_lock "$PWD/new/dir/x.lock"
  [ -f "$PWD/new/dir/x.lock" ]
  od_unlock "$PWD/new/dir/x.lock"
}

# shellcheck disable=SC2031
test_lock_serializes_parallel_increments() {
  load_common
  local lock=$PWD/p.lock n=$PWD/counter fails=$PWD/fails
  # Process creation is slow on Windows, so the default wait could expire legitimately.
  export OD_LOCK_TIMEOUT=60
  printf '0\n' > "$n"
  for _ in 1 2 3 4 5 6; do
    (
      . "$(dirname "$(dirname "$RUNNER")")/plugins/overdrive/lib/common.sh"
      j=0
      while [ "$j" -lt 5 ]; do
        od_lock "$lock" || { echo lock-timeout >> "$fails"; exit 1; }
        read -r v < "$n"
        printf '%s\n' $((v + 1)) > "$n"
        od_unlock "$lock"
        j=$((j + 1))
      done
    ) &
  done
  wait
  [ ! -e "$fails" ]
  read -r v < "$n"
  assert_eq 30 "$v"
}

test_unlock_refuses_foreign_lock() {
  load_common
  local lock=$PWD/f.lock
  printf '1\n' > "$lock"
  od_unlock "$lock" && return 1
  [ -f "$lock" ]
}

test_repo_root_resolves_dot_segments() {
  load_common
  local repo
  repo=$(make_repo)
  mkdir -p "$repo/a/b"
  assert_eq "$(sq "$repo")" "$(od_repo_root "$repo/a/./b/../b//")"
  assert_eq "$(sq "$repo")" "$(od_repo_root "$repo/a/b/../../a")"
}

# spawn_lock_worker LOCK COUNTER OCC FAILS ITER: a real separate process (own pid) that
# takes the lock ITER times, increments the counter and checks nobody else is inside.
spawn_lock_worker() {
  LOCK=$1 COUNTER=$2 OCC=$3 FAILS=$4 ITER=$5 COMMON="$(dirname "$(dirname "$RUNNER")")/plugins/overdrive/lib/common.sh" \
    bash -c '
      . "$COMMON"
      j=0
      while [ "$j" -lt "$ITER" ]; do
        od_lock "$LOCK" || { echo timeout >> "$FAILS"; exit 1; }
        ( set -C; : > "$OCC" ) 2>/dev/null || echo overlap >> "$FAILS"
        read -r v < "$COUNTER"
        printf "%s\n" $((v + 1)) > "$COUNTER"
        rm -f "$OCC"
        od_unlock "$LOCK"
        j=$((j + 1))
      done
    ' &
}

# dead_pid: print the pid of a process that has already exited.
dead_pid() {
  local p
  p=$(bash -c 'echo $$')
  printf '%s\n' "$p"
}

test_lock_many_breakers_never_double_hold() {
  load_common
  export OD_LOCK_TIMEOUT=60
  local lock=$PWD/b.lock counter=$PWD/bc occ=$PWD/occ fails=$PWD/bfails w
  printf '0\n' > "$counter"
  for _ in 1 2 3 4; do
    dead_pid > "$lock"
    for w in 1 2 3 4 5 6; do spawn_lock_worker "$lock" "$counter" "$occ" "$fails" 1; done
    wait
  done
  [ ! -e "$fails" ] || { cat "$fails" >&2; return 1; }
  read -r w < "$counter"
  assert_eq 24 "$w"
  [ ! -e "$lock" ]
  [ ! -e "$lock.break" ]
}

test_lock_empty_lock_seen_for_two_seconds_is_stale() {
  load_common
  local lock=$PWD/pl.lock
  : > "$lock"
  OD_LOCK_TIMEOUT=8 od_lock "$lock"
  assert_eq "$$" "$(cat "$lock")"
  od_unlock "$lock"
}

test_lock_empty_lock_is_respected_briefly() {
  load_common
  local lock=$PWD/pf.lock
  : > "$lock"
  OD_LOCK_TIMEOUT=0 od_lock "$lock" && return 1
  [ -f "$lock" ]
}

test_lock_stale_break_marker_expires() {
  load_common
  local lock=$PWD/sb.lock
  dead_pid > "$lock"
  : > "$lock.break"
  OD_LOCK_TIMEOUT=10 od_lock "$lock"
  od_unlock "$lock"
  [ ! -e "$lock.break" ]
}

test_lock_fresh_break_marker_blocks_until_timeout() {
  load_common
  local lock=$PWD/fb.lock
  dead_pid > "$lock"
  : > "$lock.break"
  OD_LOCK_TIMEOUT=1 od_lock "$lock" && return 1
  return 0
}

test_lock_times_out_when_break_cannot_proceed() {
  load_common
  # A stale lock inside a directory that cannot be modified must not spin forever.
  local parent=$PWD/ro lock rc=0
  mkdir "$parent"
  lock=$parent/x.lock
  dead_pid > "$lock"
  chmod a-w "$parent"
  if touch "$parent/probe" 2>/dev/null; then
    chmod u+w "$parent"
    echo "skip: directory permissions are not enforced here"
    return 0
  fi
  OD_LOCK_TIMEOUT=1 od_lock "$lock" || rc=$?
  chmod u+w "$parent"
  assert_eq 1 "$rc"
}

test_lock_unlock_removes_the_file() {
  load_common
  local lock=$PWD/u.lock
  od_lock "$lock"
  od_unlock "$lock"
  [ ! -e "$lock" ]
  # Releasing a lock that is already gone is not an error loop.
  od_unlock "$lock" || true
}

test_lock_live_holder_without_permission_is_alive() {
  load_common
  # pid 1 exists and belongs to another user: kill -0 fails with EPERM, which means alive.
  local lock=$PWD/ep.lock
  [ "$(id -u)" != 0 ] || { echo "skip: running as root"; return 0; }
  case $OSTYPE in msys* | cygwin*) echo "skip: no foreign pid 1 on Windows"; return 0 ;; esac
  printf '1\n' > "$lock"
  OD_LOCK_TIMEOUT=1 od_lock "$lock" && return 1
  [ -f "$lock" ]
}

# shellcheck disable=SC2031
test_posix_path_spellings() {
  load_common
  OSTYPE=msys
  _od_posix_path 'C:\Users\x\repo'
  assert_eq /c/Users/x/repo "$_OD_PATH"
  _od_posix_path 'C:/Users/x/repo'
  assert_eq /c/Users/x/repo "$_OD_PATH"
  _od_posix_path '/c/Users/x/repo'
  assert_eq /c/Users/x/repo "$_OD_PATH"
  OSTYPE=linux-gnu
  _od_posix_path 'c:/odd/but/relative'
  assert_eq 'c:/odd/but/relative' "$_OD_PATH"
}

test_repo_root_windows_spellings_agree() {
  load_common
  case $OSTYPE in msys* | cygwin*) ;; *) echo "skip: not Git Bash"; return 0 ;; esac
  local repo want mixed
  repo=$(make_repo)
  mkdir -p "$repo/sub"
  want=$(cd -P "$repo" && pwd)
  # Spellings come from the resolved path: a temp dir may also have an 8.3 short name.
  mixed=$(cygpath -m "$want")
  assert_eq "$want" "$(od_repo_root "$mixed/sub")"
  assert_eq "$want" "$(od_repo_root "$(cygpath -w "$want")\\sub")"
  assert_eq "$want" "$(od_repo_root "$want/sub")"
}

test_lock_separate_processes_serialize() {
  load_common
  export OD_LOCK_TIMEOUT=60
  local lock=$PWD/sp.lock counter=$PWD/spc occ=$PWD/spocc fails=$PWD/spfails w
  printf '0\n' > "$counter"
  for w in 1 2 3 4 5 6; do spawn_lock_worker "$lock" "$counter" "$occ" "$fails" 5; done
  wait
  [ ! -e "$fails" ] || { cat "$fails" >&2; return 1; }
  read -r w < "$counter"
  assert_eq 30 "$w"
  [ ! -e "$lock" ]
}

test_lock_live_breaker_marker_is_not_expired() {
  load_common
  local lock=$PWD/lb.lock rc=0
  dead_pid > "$lock"
  sleep 8 &
  local breaker=$!
  printf '%s\n' "$breaker" > "$lock.break"
  OD_LOCK_TIMEOUT=4 od_lock "$lock" || rc=$?
  kill "$breaker" 2>/dev/null || true
  wait "$breaker" 2>/dev/null || true
  assert_eq 1 "$rc"
  [ -e "$lock.break" ]
}

test_lock_dead_breaker_marker_is_dropped() {
  load_common
  local lock=$PWD/db.lock
  dead_pid > "$lock"
  dead_pid > "$lock.break"
  OD_LOCK_TIMEOUT=5 od_lock "$lock"
  assert_eq "$$" "$(cat "$lock")"
  od_unlock "$lock"
}

test_unlock_keeps_a_lock_that_is_not_ours() {
  load_common
  local lock=$PWD/nu.lock
  : > "$lock"
  od_unlock "$lock" && return 1
  [ -f "$lock" ]
  od_unlock "$PWD/missing.lock"
}

test_lock_on_a_directory_fails_at_once() {
  load_common
  local lock=$PWD/dl.lock start=$SECONDS rc=0 err
  mkdir "$lock"
  err=$(OD_LOCK_TIMEOUT=30 od_lock "$lock" 2>&1) || rc=$?
  assert_eq 1 "$rc"
  [ $((SECONDS - start)) -le 2 ]
  case $err in *directory*) ;; *) echo "no clear error: $err" >&2; return 1 ;; esac
}
