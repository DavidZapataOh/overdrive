#!/usr/bin/env bash
# PreToolUse guard checks that need more than the fast path: pinned files and pushes
# to the default branch. Sourced by hooks/pre-tool-use after json.sh and path.sh,
# never executed. Every deny prints the decision and exits the hook.

if [ -n "${_OD_GUARD_LOADED:-}" ]; then return 0; fi
_OD_GUARD_LOADED=1

# shellcheck disable=SC2154  # plugin is set by the hook that sources this file
PIN_TAIL="Tests change only before the red run. If the test itself is wrong, run: $plugin/bin/overdrive pin --release \"<reason>\" and redo red."

deny() {
  printf '%s' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"'
  json_escape "$1"
  printf '%s\n' '"}}'
  exit 0
}

deny_pinned() { deny "$1 is a pinned test. $PIN_TAIL"; }

deny_invalid() {
  deny "Pinned tests are active in $1, but $PINS_FILE cannot be parsed, so changes to that repository are blocked. If the pins are wrong, run: $plugin/bin/overdrive pin --release \"<reason>\" and redo red."
}

deny_switch() {
  deny "Switching branches is blocked while tests are pinned in $1: the pinned tests would change under the red run. Finish green and run $plugin/bin/overdrive pin --clear, or, if the test itself is wrong, run: $plugin/bin/overdrive pin --release \"<reason>\" and redo red."
}

deny_pins_file() {
  deny "$PINS_FILE is written only by $plugin/bin/overdrive pin. $PIN_TAIL"
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
  done 2>/dev/null < "$1/$PINS_FILE"
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

# covers ABS DIR GLOB: true when ABS is DIR or one of its ancestors (with GLOB, a glob
# matching one of them).
covers() {
  local a=$2
  [ "$1" != / ] || return 0
  while [ -n "$a" ]; do
    [ "$a" != "$1" ] || return 0
    if [ -n "$3" ]; then
      # shellcheck disable=SC2254
      case $a in $1) return 0 ;; esac
    fi
    a=${a%/*}
  done
  return 1
}

# check_target ABS TREE GLOB: deny when ABS (absolute, normalized) names a pinned file
# of its repo (see hits), or the pins file itself.
check_target() {
  local abs=$1 root rel p
  if [ -n "$2" ] && [ -n "$croot" ] && covers "$abs" "$croot" "$3"; then
    # The repository itself or a directory above it holds every pinned file.
    root=$croot
    rel=''
  elif _od_find_root "$abs"; then
    root=$_OD_ROOT
    if [ "$root" = / ]; then rel=${abs#/}; else rel=${abs#"$root"/}; fi
    [ "$abs" != "$root" ] || rel=''
  else
    return 0
  fi
  load_pins "$root" || return 0
  [ "$PINS_OK" = 1 ] || deny_invalid "$root"
  for p in "${PINNED[@]}"; do
    ! hits "$rel" "$p" "$2" "$3" || deny_pinned "$p"
  done
  ! hits "$rel" "$PINS_FILE" "$2" "$3" || deny_pins_file
}

# check_switch DIR switch | DIR OP...: deny a branch switch in a repo with pins. A
# checkout whose every operand exists as a path restores files instead (the
# operands were checked as written files already).
check_switch() {
  local dir=$1 op
  shift
  _od_find_root "$dir" || return 0
  load_pins "$_OD_ROOT" || return 0
  if [ "$1" != switch ]; then
    for op in "$@"; do
      case $op in -*) continue ;; esac
      absolute "$dir" "$op"
      [ -e "$ABS" ] || deny_switch "$_OD_ROOT"
    done
    return 0
  fi
  deny_switch "$_OD_ROOT"
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
    dst=${dst#refs/}
    dst=${dst#heads/}
    [ -n "$dst" ] || continue
    for d in $defaults; do
      # shellcheck disable=SC2254
      case $d in $dst) deny_push "$d" ;; esac
    done
  done
}


# abs_under ROOT PATH: set ABS_PATH to PATH as git printed it, made absolute under ROOT
# when it is relative (a drive-letter path is absolute too).
abs_under() {
  case $2 in
    /* | [A-Za-z]:*) ABS_PATH=$2 ;;
    *) ABS_PATH=$1/$2 ;;
  esac
}

# git_path ROOT NAME: set ABS_PATH to the absolute path of NAME inside ROOT's git directory.
git_path() {
  local p
  p=$(git -C "$1" rev-parse --git-path "$2" 2>/dev/null) || return 1
  abs_under "$1" "$p"
}

# replay_adds IDX: apply the git add and git rm commands that ran before the commit in the
# same command line to the scratch index IDX, as the commit will see them.
replay_adds() {
  local rec f d op ops
  while IFS= read -r rec; do
    [ -n "$rec" ] || continue
    IFS=$US read -r -a f <<<"$rec"
    d=${f[1]}
    if [ "${f[2]}" = add ] || [ "${f[2]}" = stage ]; then
      GIT_INDEX_FILE=$1 git -C "$d" add "${f[@]:3}" >/dev/null 2>&1 </dev/null || :
    else
      ops=()
      for op in "${f[@]:3}"; do
        case $op in -*) ;; *) ops[${#ops[@]}]=$op ;; esac
      done
      # Only the index: the files themselves are not touched.
      GIT_INDEX_FILE=$1 git -C "$d" rm -q -r --cached --ignore-unmatch -- ${ops[@]+"${ops[@]}"} >/dev/null 2>&1 </dev/null || :
    fi
  done <<<"$PRIOR_ADDS"
}

# commit_classify ROOT DIR FLAGS [PATH...]: set COMMIT_ITEMS and COMMIT_PATHS to the domain
# items (critical floor, project-map and computed items such as a deploy script; not
# untested-change, test-removed or risk-map) of what a git commit would record, and the
# files that raise them. The index by default, with the git add and git rm that ran
# before the commit replayed on a scratch copy of it; the tracked changes for -a and
# pathspec operands; the whole working tree when another command may have changed content
# (flag s). The scratch index lives in the git directory and the real one is never
# touched. An unborn HEAD classifies against the empty tree. Fails when the classifier
# cannot say.
commit_classify() {
  local root=$1 dir=$2 flags=$3 out='' line rc=0 idx='' unborn='' tree empty scratch='' ev
  shift 3
  COMMIT_ITEMS='' COMMIT_PATHS=''
  git -C "$root" rev-parse -q --verify 'HEAD^{commit}' >/dev/null 2>&1 || unborn=1
  if [ -z "$unborn" ] && [[ $flags == *s* ]]; then
    out=$(cd "$root" 2>/dev/null && "${BASH:-bash}" "$plugin/bin/overdrive" risk --worktree 2>/dev/null </dev/null) || rc=$?
  else
    [ -z "$unborn" ] && [ -z "$PRIOR_ADDS" ] && [ -z "${flags//[!a]/}" ] && [ "$#" -eq 0 ] || scratch=1
    if [ -n "$scratch" ]; then
      git_path "$root" "od-index.$$" || return 1
      idx=$ABS_PATH
      git_path "$root" index || return 1
      # -p keeps the index time git compares with file times to spot same-second edits.
      { [ ! -f "$ABS_PATH" ] || cp -p "$ABS_PATH" "$idx"; } 2>/dev/null
      if [[ $flags == *s* ]]; then
        GIT_INDEX_FILE=$idx git -C "$root" add -A >/dev/null 2>&1 </dev/null || { rm -f "$idx"; return 1; }
      else
        replay_adds "$idx"
        if [ "$#" -gt 0 ]; then
          GIT_INDEX_FILE=$idx git -C "$dir" add -u -- "$@" >/dev/null 2>&1 </dev/null || { rm -f "$idx"; return 1; }
        elif [ -n "${flags//[!a]/}" ]; then
          GIT_INDEX_FILE=$idx git -C "$root" add -u >/dev/null 2>&1 </dev/null || { rm -f "$idx"; return 1; }
        fi
      fi
      if [ -n "$unborn" ]; then
        # With no first commit the classifier has nothing to compare against: use the empty tree.
        tree=$(GIT_INDEX_FILE=$idx git -C "$root" write-tree 2>/dev/null </dev/null) || { rm -f "$idx"; return 1; }
        empty=$(git -C "$root" hash-object -t tree --stdin 2>/dev/null </dev/null) || { rm -f "$idx"; return 1; }
        out=$(cd "$root" 2>/dev/null && "${BASH:-bash}" "$plugin/bin/overdrive" risk --diff "$empty..$tree" 2>/dev/null </dev/null) || rc=$?
      else
        out=$(cd "$root" 2>/dev/null && GIT_INDEX_FILE=$idx "${BASH:-bash}" "$plugin/bin/overdrive" risk --staged 2>/dev/null </dev/null) || rc=$?
      fi
      rm -f "$idx"
    else
      out=$(cd "$root" 2>/dev/null && "${BASH:-bash}" "$plugin/bin/overdrive" risk --staged 2>/dev/null </dev/null) || rc=$?
    fi
  fi
  [ "$rc" -eq 0 ] || return 1
  while IFS= read -r line; do
    case $line in
      'item '*)
        # item NAME LANE SOURCE path P | line P:N. Items about the change's shape, not its
        # domain, do not gate; the risk map is gated by its own review.
        # shellcheck disable=SC2086  # globbing is off in the hook
        set -- $line
        [ "${3-}" = critical ] || continue
        case $2 in untested-change | test-removed | risk-map | deletion | exec-bit) continue ;; esac
        case ", $COMMIT_ITEMS," in *", $2,"*) ;; *) COMMIT_ITEMS=$COMMIT_ITEMS${COMMIT_ITEMS:+, }$2 ;; esac
        ev=${6-}
        [ "${5-}" != line ] || ev=${ev%:*}
        [ -z "$ev" ] || case $'\n'$COMMIT_PATHS in *$'\n'"$ev"$'\n'*) ;; *) COMMIT_PATHS=$COMMIT_PATHS$ev$'\n' ;; esac
        ;;
    esac
  done <<<"$out"
  return 0
}

# commit_message MSG FILE: print the commit message the command gives: -m text and the
# content of a -F file (relative to the commit's directory).
commit_message() {
  local file=${2#f}
  printf '%s\n' "${1#m}"
  [ -z "$file" ] || [ ! -f "$file" ] || cat -- "$file" 2>/dev/null
}

# main_root ROOT: set MAIN_ROOT to the main worktree of the repository ROOT belongs to.
main_root() {
  local c
  c=$(git -C "$1" rev-parse --git-common-dir 2>/dev/null) || return 1
  abs_under "$1" "$c"
  MAIN_ROOT=${ABS_PATH%/.git}
  MAIN_ROOT=${MAIN_ROOT%/.git/}
}

# commit_gate DIR FLAGS MSG FILE [PATH...]: deny a git commit whose content has a domain
# risk item unless the critical flow is under way: the dispatched builder commits (it
# commits its own task before the review the flow then requires), the active ledger of
# this branch (any branch while a merge is being concluded; the main worktree's when this
# one has none) has a task marked critical, or the commit message cites an active
# decision in which the user lowered the lane for every file involved. The classifier
# runs only for commits, and one that cannot run lets the call through like every other
# failure of the guard.
# shellcheck disable=SC2154  # input and cmd belong to the hook
commit_gate() {
  local dir=$1 flags=$2 msg=$3 mfile=$4 root id='' why='' cli any='' text gd p lroot shown='' n=0
  shift 4
  case $flags in *n*) return 0 ;; esac
  _od_find_root "$dir" || return 0
  root=$_OD_ROOT
  in_plugin "$dir" && return 0
  if json_extract_string agent_type "$input"; then
    [ "$JSON_VALUE" != overdrive:builder ] || return 0
  fi
  commit_classify "$root" "$dir" "$flags" "$@" || return 0
  [ -n "$COMMIT_ITEMS" ] || return 0
  text=$(cd "$dir" 2>/dev/null && commit_message "$msg" "$mfile")
  if [[ $text =~ \(lowered\ by\ user,\ (D-[0-9]{4,})\) ]]; then
    id=${BASH_REMATCH[1]}
    # shellcheck source=lowering.sh
    . "$plugin/lib/lowering.sh"
    BASE=HEAD
    if ! decision "$root" "$id" || [ "$D_STATUS" != active ]; then
      why=" $id is not an active decision in .overdrive/decisions.md."
    elif ! lowers_lane; then
      why=" $id does not lower a lane (\"Handle this change as direct instead of critical.\")."
    elif ! in_base "$root" "$id" && ! users_words "$D_SOURCE"; then
      why=" $id has no Source quoting the user's own words, so it cannot lower the lane."
    else
      while IFS= read -r p; do
        [ -z "$p" ] || scope_covers "$p" || { why=" $id has a Scope that does not cover $p."; break; }
      done <<<"$COMMIT_PATHS"
      [ -n "$why" ] || return 0
    fi
  fi
  # Concluding a merge or squash of a reviewed critical slice happens on another branch.
  for gd in MERGE_HEAD SQUASH_MSG; do
    if git_path "$root" "$gd" && [ -e "$ABS_PATH" ]; then any=--any-branch; fi
  done
  lroot=$root
  if [ ! -f "$root/.overdrive/run/active-ledger" ] && main_root "$root"; then lroot=$MAIN_ROOT; fi
  if [ -f "$lroot/.overdrive/run/active-ledger" ] &&
    (cd "$lroot" 2>/dev/null && "${BASH:-bash}" "$plugin/bin/overdrive" ledger critical-flow $any >/dev/null 2>&1 </dev/null); then
    return 0
  fi
  while IFS= read -r p; do
    [ -z "$p" ] || [ "$n" -ge 5 ] || { shown=$shown${shown:+, }$p; n=$((n + 1)); }
  done <<<"$COMMIT_PATHS"
  cli="'$plugin/bin/overdrive'"
  deny "Committing this change is blocked: it has critical risk ($COMMIT_ITEMS) in ${shown:-the files it records} and no critical flow is active on this branch. The user's approval of a plan approves the plan's content, not skipping the lane. Load overdrive:decision-planning and write the plan, run $cli ledger init --plan <plan file>, then for each task run $cli brief --plan <plan file> --task <N> (it marks the task critical), build and commit it here test-first and review it with overdrive:critical-reviewer. If the user lowers the lane instead (overdrive:risk-triage, rule 5), record the decision and cite it in the commit message as (lowered by user, D-NNNN).$why"
}
