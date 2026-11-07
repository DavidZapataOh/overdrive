#!/usr/bin/env bash
# Path helpers shared by the CLI and the hooks. Sourced, never executed. Hooks run
# before every tool call, so everything here except od_abs_path uses builtins only.

if [ -n "${_OD_PATH_LOADED:-}" ]; then return 0; fi
_OD_PATH_LOADED=1

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
  _od_find_root "${1:-$PWD}" || return 1
  printf '%s\n' "$_OD_ROOT"
}

# _od_find_root DIR: od_repo_root without the output, for callers that must not fork:
# sets _OD_ROOT (and _OD_PATH to DIR in the same normalized form). DIR need not exist.
_od_find_root() {
  local d p
  _od_posix_path "$1"
  d=$_OD_PATH
  case $d in /* | [A-Za-z]:*) ;; *) d=$PWD/$d ;; esac
  case $d/ in */./* | */../* | *//*) _od_normalize_path "$d"; d=$_OD_PATH ;; esac
  while [ "${d%/}" != "$d" ]; do d=${d%/}; done
  _OD_PATH=$d
  _OD_ROOT=
  while :; do
    if [ -e "$d/.git" ]; then
      _OD_ROOT=${d:-/}
      return 0
    fi
    [ -n "$d" ] || return 1
    p=${d%/*}
    [ "$p" != "$d" ] || return 1
    d=$p
  done
}

# od_abs_path PATH: print PATH made absolute the way od_repo_root sees paths: Windows
# spellings in /c/x form, relative paths prefixed with the physical cwd, and ., .. and
# repeated slashes collapsed lexically.
od_abs_path() {
  _od_posix_path "$1"
  case $_OD_PATH in /* | [A-Za-z]:*) ;; *) _OD_PATH=$(pwd -P)/$_OD_PATH ;; esac
  _od_normalize_path "$_OD_PATH"
  printf '%s\n' "$_OD_PATH"
}
