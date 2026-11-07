#!/usr/bin/env bash
# PreToolUse guard checks that need more than the fast path: pinned files and pushes
# to the default branch. Sourced by hooks/pre-tool-use after json.sh and path.sh,
# never executed. Every deny prints the decision and exits the hook.

if [ -n "${_OD_GUARD_LOADED:-}" ]; then return 0; fi
_OD_GUARD_LOADED=1

PIN_TAIL='Tests change only before the red run. If the test itself is wrong, run: overdrive pin --release "<reason>" and redo red.'

deny() {
  printf '%s' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"'
  json_escape "$1"
  printf '%s\n' '"}}'
  exit 0
}

deny_pinned() { deny "$1 is a pinned test. $PIN_TAIL"; }

deny_invalid() {
  deny "Pinned tests are active in $1, but $PINS_FILE cannot be parsed, so changes to that repository are blocked. If the pins are wrong, run: overdrive pin --release \"<reason>\" and redo red."
}

deny_pins_file() {
  deny "$PINS_FILE is written only by overdrive pin. $PIN_TAIL"
}

# load_pins ROOT: parse ROOT's pins into PINNED and set PINS_OK (1 valid, 0 invalid).
# Returns 1 when ROOT has no pins. The commit and blobs are not checked here (that
# takes git); the seal catches hand edits, and a file that fails it blocks changes.
PINS_ROOT='' PINS_OK=0 PINNED=()
load_pins() {
  local line n=0 body='' seal='' sum
  if [ "$1" = "$PINS_ROOT" ]; then
    [ -n "$PINS_ROOT" ] && return 0
  fi
  [ -f "$1/$PINS_FILE" ] || return 1
  PINS_ROOT=$1 PINS_OK=0 PINNED=()
  while IFS= read -r line || [ -n "$line" ]; do
    n=$((n + 1))
    [ -z "$seal" ] || return 0
    case $n:$line in
      1:'sha '?*) ;;
      1:*) return 0 ;;
      *:'path '?*' '?*) PINNED[${#PINNED[@]}]=${line#path * } ;;
      *:'seal '?*) seal=${line#seal }; continue ;;
      *) return 0 ;;
    esac
    body=${body:+$body$'\n'}$line
  done < "$1/$PINS_FILE"
  [ -n "$seal" ] && [ "${#PINNED[@]}" -gt 0 ] || return 0
  sum=$(cksum <<<"$body") || return 0
  [ "${sum%% *}" = "$seal" ] && PINS_OK=1
  return 0
}

# hits PATTERN PATH TREE GLOB: true when PATTERN names PATH. PATTERN is repo-relative;
# an empty one is the repo itself. With TREE, a directory also names everything below
# it; with GLOB, PATTERN may be a shell glob (still matched literally first, since
# names such as app/[id]/page.tsx are real). Case-insensitive file systems compare
# without case.
hits() {
  local pat=$1 p=$2 a rc=1
  case $OSTYPE in darwin* | msys* | cygwin*) shopt -s nocasematch ;; esac
  case $4:$pat in
    ?*:*[*?[]*)
      a=$p
      while :; do
        if [[ $a == "$pat" ]]; then rc=0; break; fi
        # shellcheck disable=SC2254
        case $a in $pat) rc=0; break ;; esac
        [ -n "$3" ] || break
        case $a in */*) a=${a%/*} ;; *) break ;; esac
      done
      ;;
    *)
      if [[ $p == "$pat" ]]; then
        rc=0
      elif [ -n "$3" ] && { [ -z "$pat" ] || [[ $p == "$pat"/* ]]; }; then
        rc=0
      fi
      ;;
  esac
  shopt -u nocasematch
  return "$rc"
}

# check_target ABS TREE GLOB: deny when ABS (absolute, normalized) names a pinned file
# of its repo (see hits), or the pins file itself.
check_target() {
  local abs=$1 root rel p
  if _od_find_root "$abs"; then
    root=$_OD_ROOT
  elif [ -n "$2" ] && [ -n "$croot" ] && [[ $croot/ == "$abs"/* ]]; then
    # A directory above the repository holds every pinned file.
    root=$croot
  else
    return 0
  fi
  load_pins "$root" || return 0
  [ "$PINS_OK" = 1 ] || deny_invalid "$root"
  if [ "$abs" = "$root" ] || [[ $root/ == "$abs"/* ]]; then
    rel=''
  elif [ "$root" = / ]; then
    rel=${abs#/}
  else
    rel=${abs#"$root"/}
  fi
  for p in "${PINNED[@]}"; do
    ! hits "$rel" "$p" "$2" "$3" || deny_pinned "$p"
  done
  ! hits "$rel" "$PINS_FILE" "$2" "$3" || deny_pins_file
}

# read_line FILE: set LINE to the first line of FILE without a trailing CR.
read_line() {
  LINE=''
  [ -f "$1" ] || return 1
  { IFS= read -r LINE || [ -n "$LINE" ]; } < "$1" 2>/dev/null || return 1
  LINE=${LINE%$'\r'}
}

# git_dirs ROOT: set GITDIR (per worktree) and COMMONDIR. A linked worktree's .git
# is a file naming its gitdir, which in turn names the shared one in commondir.
git_dirs() {
  if [ -d "$1/.git" ]; then
    GITDIR=$1/.git
  else
    read_line "$1/.git" || return 1
    case $LINE in 'gitdir: '?*) ;; *) return 1 ;; esac
    _od_posix_path "${LINE#gitdir: }"
    case $_OD_PATH in /* | [A-Za-z]:*) GITDIR=$_OD_PATH ;; *) GITDIR=$1/$_OD_PATH ;; esac
  fi
  COMMONDIR=$GITDIR
  if read_line "$GITDIR/commondir"; then
    _od_posix_path "$LINE"
    case $_OD_PATH in /* | [A-Za-z]:*) COMMONDIR=$_OD_PATH ;; *) COMMONDIR=$GITDIR/$_OD_PATH ;; esac
  fi
}

deny_push() {
  deny "git push to $1, the default branch, is blocked: changes reach it through a pull request. Push a branch and open one."
}

# check_push DIR ARG...: deny a push from DIR that would update the default branch.
check_push() {
  local dir=$1 a pos=() del='' all='' tags='' skip='' dd='' remote cur='' dst d defaults
  shift
  _od_find_root "$dir" || return 0
  git_dirs "$_OD_ROOT" || return 0
  for a in "$@"; do
    if [ -n "$skip" ]; then skip=''; continue; fi
    if [ -n "$dd" ]; then pos[${#pos[@]}]=$a; continue; fi
    case $a in
      --) dd=1 ;;
      --dry-run) return 0 ;;
      --all | --branches | --mirror) all=1 ;;
      --delete) del=1 ;;
      --tags) tags=1 ;;
      --repo=*) pos=("${a#--repo=}" "${pos[@]}") ;;
      --repo | --push-option | --receive-pack | --exec) skip=1 ;;
      --*) ;;
      -*o) skip=1 ;;
      -*)
        case $a in *n*) return 0 ;; esac
        case $a in *d*) del=1 ;; esac
        ;;
      *) pos[${#pos[@]}]=$a ;;
    esac
  done
  remote=${pos[0]:-origin}
  case $remote in */* | *:* | *\\*) remote=origin ;; esac
  defaults='main master'
  if read_line "$COMMONDIR/refs/remotes/$remote/HEAD"; then
    case $LINE in "ref: refs/remotes/$remote/"?*) defaults=${LINE#"ref: refs/remotes/$remote/"} ;; esac
  fi
  if read_line "$GITDIR/HEAD"; then
    case $LINE in 'ref: refs/heads/'?*) cur=${LINE#ref: refs/heads/} ;; esac
  fi
  if [ -n "$all" ]; then
    deny_push "${defaults%% *}"
  fi
  if [ "${#pos[@]}" -le 1 ]; then
    [ -z "$del$tags" ] || return 0
    for d in $defaults; do
      [ "$cur" != "$d" ] || deny_push "$d"
    done
    return 0
  fi
  for a in "${pos[@]:1}"; do
    a=${a#+}
    case $a in
      *:*) dst=${a#*:}; [ -n "$dst" ] || dst=${a%%:*} ;;
      *) dst=$a ;;
    esac
    case $dst in HEAD | @) dst=$cur ;; esac
    dst=${dst#refs/heads/}
    [ -n "$dst" ] || continue
    for d in $defaults; do
      # shellcheck disable=SC2254
      case $d in $dst) deny_push "$d" ;; esac
    done
  done
}

