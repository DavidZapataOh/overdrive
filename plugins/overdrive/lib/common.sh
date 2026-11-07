#!/usr/bin/env bash
# Shared helpers for the overdrive CLI and hooks. Sourced, never executed.

if [ -n "${_OD_COMMON_LOADED:-}" ]; then return 0; fi
_OD_COMMON_LOADED=1

# od_die MESSAGE [CODE]: report on stderr and exit the calling shell.
od_die() {
  printf 'overdrive: %s\n' "$1" >&2
  exit "${2:-1}"
}

# _od_normalize_path PATH: set _OD_PATH with . and .. segments and repeated
# slashes resolved lexically (no symlink resolution, no forks).
_od_normalize_path() {
  local rest=$1 seg out="" lead=""
  case $rest in /*) lead=/ ;; esac
  while [ -n "$rest" ]; do
    case $rest in
      */*) seg=${rest%%/*}; rest=${rest#*/} ;;
      *) seg=$rest; rest= ;;
    esac
    case $seg in
      '' | .) ;;
      ..)
        case $out in
          '' | .. | */..) out=${out:+$out/}.. ;;
          */*) out=${out%/*} ;;
          *) out= ;;
        esac
        ;;
      *) out=${out:+$out/}$seg ;;
    esac
  done
  _OD_PATH=$lead$out
}

# _od_posix_path PATH: set _OD_PATH with backslashes turned into slashes and, under
# Git Bash or Cygwin, a drive prefix (C:/x) rewritten to the /c/x form that $PWD uses,
# so every spelling of one location compares equal.
_od_posix_path() {
  local d=${1//\\//} drive upper=ABCDEFGHIJKLMNOPQRSTUVWXYZ lower=abcdefghijklmnopqrstuvwxyz pre
  case $OSTYPE in
    msys* | cygwin*)
      case $d in
        [A-Za-z]:/* | [A-Za-z]:)
          drive=${d:0:1}
          case $drive in
            [A-Z]) pre=${upper%%"$drive"*}; drive=${lower:${#pre}:1} ;;
          esac
          d=/$drive${d:2}
          ;;
      esac
      ;;
  esac
  _OD_PATH=$d
}

# od_repo_root [DIR]: print the nearest ancestor of DIR (default $PWD) that holds a
# .git entry, file or directory, so linked worktrees count. Builtins only. The
# environment's project dir is deliberately ignored: sessions often start in a
# folder above the repository, and the tool's own cwd or file path is the truth.
od_repo_root() {
  local d=${1:-$PWD} p
  _od_posix_path "$d"
  d=$_OD_PATH
  case $d in /* | [A-Za-z]:*) ;; *) d=$PWD/$d ;; esac
  case $d/ in */./* | */../* | *//*) _od_normalize_path "$d"; d=$_OD_PATH ;; esac
  while [ "${d%/}" != "$d" ]; do d=${d%/}; done
  while :; do
    if [ -e "$d/.git" ]; then
      printf '%s\n' "${d:-/}"
      return 0
    fi
    [ -n "$d" ] || return 1
    p=${d%/*}
    [ "$p" != "$d" ] || return 1
    d=$p
  done
}

# od_run_dir ROOT: ensure ROOT/.overdrive/run exists and ignores itself; print it.
od_run_dir() {
  local run=$1/.overdrive/run
  mkdir -p "$run" || return 1
  [ -f "$run/.gitignore" ] || printf '*\n' > "$run/.gitignore" || return 1
  printf '%s\n' "$run"
}

# _od_pid_dead PID: true only when the process does not exist. kill -0 also fails with
# EPERM for a live process owned by someone else, which must count as alive.
_od_pid_dead() {
  local out
  out=$(export LC_ALL=C; kill -0 "$1" 2>&1) && return 1
  case $out in *"No such process"*) return 0 ;; esac
  return 1
}

# od_lock FILE: mutex held as a file that contains the owner pid. It is created with
# a noclobber redirection (O_EXCL, a bash builtin), not mkdir: mkdir is not atomic in
# every coreutils build (the Rust one that ships by default on current Ubuntu lets
# two racing callers both succeed). Waits up to OD_LOCK_TIMEOUT seconds (default 5)
# and returns 1 on timeout so callers fail closed; a directory at FILE fails at once.
# A lock is stale when its pid is dead, or when this waiter has seen it empty for two
# seconds (the holder died between creating it and writing the pid). Ages are measured
# by the waiter's own clock, not file times, which differ across platforms.
# Breakers serialize on FILE.break, which holds the breaker's pid; it is dropped when
# that pid is dead, or when it has stayed empty for three seconds (a breaker killed
# before writing it). The observation restarts whenever the marker is absent or its
# content changes. The breaker re-reads the lock under the marker and removes it only
# if it is still the same stale one. Residual: a breaker stalled between that check and
# its rm for longer than the marker expiry could remove a lock taken meanwhile.
# Pids come from $$, so a subshell shares its parent's identity.
od_lock() {
  local file=$1 start=$SECONDS timeout=${OD_LOCK_TIMEOUT:-5} parent=${1%/*} pid stale broke
  local empty_since='' seen='' seen_since='' mark
  if [ "$parent" != "$file" ] && [ ! -d "$parent" ]; then
    mkdir -p "$parent" || return 1
  fi
  while :; do
    if (set -C; printf '%s\n' "$$" > "$file") 2>/dev/null; then
      return 0
    fi
    if [ -d "$file" ]; then
      printf 'overdrive: lock path is a directory: %s\n' "$file" >&2
      return 1
    fi
    pid=''
    # A pid line without its newline is a write in progress.
    [ -r "$file" ] && { IFS= read -r pid < "$file" || pid=''; } 2>/dev/null
    stale=
    if [ -n "$pid" ]; then
      empty_since=''
      ! _od_pid_dead "$pid" || stale=1
    elif [ -f "$file" ]; then
      [ -n "$empty_since" ] || empty_since=$SECONDS
      [ $((SECONDS - empty_since)) -lt 2 ] || stale=1
    else
      empty_since=''
    fi
    broke=
    if [ -z "$stale" ]; then
      seen=''
      seen_since=''
    elif (set -C; printf '%s\n' "$$" > "$file.break") 2>/dev/null; then
      ! _od_break_stale "$file" "$pid" || broke=1
      rm -f "$file.break"
      seen=''
      seen_since=''
    elif [ -e "$file.break" ]; then
      mark=''
      [ -r "$file.break" ] && { IFS= read -r mark < "$file.break" || mark=''; } 2>/dev/null
      if [ "$mark" != "$seen" ] || [ -z "$seen_since" ]; then
        seen=$mark
        seen_since=$SECONDS
      fi
      if [ -n "$mark" ]; then
        # Re-read just before removing so a marker retaken in between is left alone.
        ! _od_pid_dead "$mark" || _od_drop_marker "$file.break" "$mark"
      elif [ $((SECONDS - seen_since)) -ge 3 ]; then
        _od_drop_marker "$file.break" ''
      fi
    else
      seen=''
      seen_since=''
    fi
    [ $((SECONDS - start)) -le "$timeout" ] || return 1
    # Retry at once only when the break removed the lock; otherwise back off.
    [ -n "$broke" ] || sleep 0.05 2>/dev/null || sleep 1
  done
}

# _od_drop_marker FILE EXPECTED: remove a break marker if it still holds EXPECTED.
_od_drop_marker() {
  local now=''
  [ -r "$1" ] && { IFS= read -r now < "$1" || now=''; } 2>/dev/null
  [ "$now" = "$2" ] && rm -f "$1"
  return 0
}

# _od_break_stale FILE PID: with FILE.break held, remove FILE only if it is still the
# stale lock that was judged. Succeeds only when it removed it.
_od_break_stale() {
  local now='' mine=''
  [ -r "$1.break" ] && { IFS= read -r mine < "$1.break" || mine=''; } 2>/dev/null
  [ "$mine" = "$$" ] || return 1
  [ -r "$1" ] && { IFS= read -r now < "$1" || now=''; } 2>/dev/null
  [ "$now" = "$2" ] || return 1
  if [ -n "$now" ]; then
    _od_pid_dead "$now" || return 1
  fi
  rm -f "$1"
}

# od_unlock FILE: release a lock this process holds; a lock held by someone else, or
# not yet carrying a pid, is left alone. Unlinking is atomic. Retried only when rm
# itself fails, because Windows can refuse to delete a file another process is
# reading at that instant.
od_unlock() {
  local pid='' n=0
  [ -e "$1" ] || return 0
  [ -r "$1" ] && { IFS= read -r pid < "$1" || pid=''; } 2>/dev/null
  [ "$pid" = "$$" ] || return 1
  # Never re-check existence: another process may already hold a fresh lock at FILE.
  until rm -f "$1" 2>/dev/null; do
    n=$((n + 1))
    [ "$n" -lt 20 ] || return 1
    sleep 0.05 2>/dev/null || sleep 1
  done
}

# od_append FILE LINE: append LINE to FILE under FILE.lock, so concurrent writers never
# interleave or lose lines (O_APPEND alone is not atomic on every supported platform).
od_append() {
  local rc=0
  od_lock "$1.lock" || { printf 'overdrive: cannot lock %s\n' "$1" >&2; return 1; }
  printf '%s\n' "$2" >> "$1" || rc=1
  od_unlock "$1.lock"
  return "$rc"
}

# od_active_ledger RUN: print the active ledger, the file named (relative to RUN) in
# RUN/active-ledger, which `overdrive ledger init` rewrites. Returns 1 when there is no
# pointer, it escapes RUN, or the ledger it names does not exist.
od_active_ledger() {
  local rel=''
  [ -r "$1/active-ledger" ] || return 1
  { IFS= read -r rel || [ -n "$rel" ]; } < "$1/active-ledger" || return 1
  case /$rel/ in //* | */../* | */./*) return 1 ;; esac
  [ -f "$1/$rel" ] || return 1
  printf '%s\n' "$1/$rel"
}
