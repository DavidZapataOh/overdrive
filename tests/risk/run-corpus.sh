#!/usr/bin/env bash
# Usage: tests/risk/run-corpus.sh --synthetic DIR
#        tests/risk/run-corpus.sh --tsv FILE --clone-cache DIR
#
# Runs the risk classifier ($OVERDRIVE_BIN, default plugins/overdrive/bin/overdrive) over a
# labeled corpus and compares lanes and items with the frozen labels.
# Per case: PASS|UNDER|OVER|ITEMS <name> <expected lane:items> <got lane:items>.
# Summary: under=N over=N critical_recall=P over_rate=P item_precision.<item>=P item_recall.<item>=P
# Exit: 0 gate met; 1 under > 0, critical_recall < 1.00 or over_rate > 0.25; 2 usage, corpus or
# environment error (including labels that differ from SHA256SUMS).
#
# Synthetic case DIR/<case>/: setup.sh builds the baseline (committed together with risk-map.conf,
# if present, as .overdrive/risk-map.conf), change.sh makes the change, and the classifier runs in
# --worktree mode. TSV rows are repo<TAB>sha<TAB>lane<TAB>items<TAB>note; repos are bare partial
# clones at CACHE/<name>.git, cloned from $OVERDRIVE_CORPUS_REMOTE/<repo>.git when missing
# (default https://github.com).

set -u

here=$(cd "$(dirname "$0")" && pwd)
root=$(cd "$here/../.." && pwd)
bin=${OVERDRIVE_BIN:-$root/plugins/overdrive/bin/overdrive}
remote=${OVERDRIVE_CORPUS_REMOTE:-https://github.com}

die() {
  printf 'run-corpus: %s\n' "$1" >&2
  exit 2
}

usage() {
  die "usage: run-corpus.sh --synthetic DIR | --tsv FILE --clone-cache DIR"
}

synthetic=""
tsv=""
cache=""
while [ "$#" -gt 0 ]; do
  case $1 in
    --synthetic | --tsv | --clone-cache)
      if [ "$#" -lt 2 ] || [ -z "$2" ]; then usage; fi
      case $1 in
        --synthetic) synthetic=$2 ;;
        --tsv) tsv=$2 ;;
        --clone-cache) cache=$2 ;;
      esac
      shift
      ;;
    *) usage ;;
  esac
  shift
done
if [ -n "$synthetic" ]; then
  if [ -n "$tsv" ] || [ -n "$cache" ]; then usage; fi
  [ -d "$synthetic" ] || die "not a directory: $synthetic"
elif [ -n "$tsv" ]; then
  [ -n "$cache" ] || usage
  [ -f "$tsv" ] || die "not a file: $tsv"
else
  usage
fi

work=$(mktemp -d "${TMPDIR:-/tmp}/corpus.XXXXXX") || die "cannot create a work directory"
trap 'rm -rf "$work"' EXIT

if command -v sha256sum >/dev/null 2>&1; then
  hasher="sha256sum"
else
  hasher="shasum -a 256"
fi

# Labels are frozen: every file of the corpus being run must match SHA256SUMS next to it, and
# every entry under that corpus must still exist.
verify_frozen() {
  local sums_dir=$1 prefix=$2 sums
  sums="$sums_dir/SHA256SUMS"
  [ -f "$sums" ] || die "missing $sums"
  (
    cd "$sums_dir" || exit 2
    if [ -d "$prefix" ]; then
      find "$prefix" -type f | LC_ALL=C sort > "$work/frozen.files"
    else
      printf '%s\n' "$prefix" > "$work/frozen.files"
    fi
    # Text-mode and binary-mode markers both normalize to two spaces.
    # shellcheck disable=SC2086
    tr '\n' '\0' < "$work/frozen.files" | xargs -0 $hasher |
      sed 's/^\([0-9a-f]*\) [ *]/\1  /' | LC_ALL=C sort > "$work/frozen.actual"
    tr -d '\r' < SHA256SUMS | sed 's/^\([0-9a-f]*\) [ *]/\1  /' |
      awk -v p="$prefix" '{ path = substr($0, index($0, "  ") + 2) } path == p || index(path, p "/") == 1' |
      LC_ALL=C sort > "$work/frozen.expected"
  ) || die "cannot hash $sums_dir"
  if ! cmp -s "$work/frozen.expected" "$work/frozen.actual"; then
    LC_ALL=C sort "$work/frozen.expected" "$work/frozen.actual" | uniq -u |
      sed 's/^[0-9a-f]*  //' | LC_ALL=C sort -u | tr '\n' ' ' | sed 's/ $//' > "$work/frozen.diff"
    die "labels differ from SHA256SUMS: $(cat "$work/frozen.diff")"
  fi
}

# classify DIR ARGS... prints "lane<TAB>items" from the classifier output; lane "error" when the
# classifier crashes or breaks its output contract.
classify() {
  local dir=$1 out rc=0
  shift
  out=$(cd "$work" && "$bin" risk --repo "$dir" "$@" 2>/dev/null) || rc=$?
  if [ "$rc" -ne 0 ] && [ "$rc" -ne 3 ]; then
    printf 'error\tnone\n'
    return
  fi
  printf '%s\n' "$out" | LC_ALL=C awk '
    $1 == "lane" && lane == "" { lane = $2 }
    $1 == "item" && NF >= 2 { items[$2] = 1 }
    END {
      if (lane != "direct" && lane != "standard" && lane != "critical") lane = "error"
      n = 0
      for (i in items) list[++n] = i
      for (i = 2; i <= n; i++)
        for (j = i; j > 1 && list[j - 1] > list[j]; j--) { t = list[j]; list[j] = list[j - 1]; list[j - 1] = t }
      s = ""
      for (i = 1; i <= n; i++) s = s (i > 1 ? "," : "") list[i]
      printf "%s\t%s\n", lane, (n ? s : "none")
    }'
}

# Sorts a comma-separated item list so that label order never matters.
normalize_items() {
  if [ "$1" = none ]; then
    printf 'none\n'
  else
    printf '%s\n' "$1" | tr ',' '\n' | LC_ALL=C sort -u | paste -s -d, -
  fi
}

valid_label() {
  case $1 in direct | standard | critical) ;; *) return 1 ;; esac
  printf '%s\n' "$2" | grep -Eq '^(none|[a-z0-9]+(-[a-z0-9]+)*(,[a-z0-9]+(-[a-z0-9]+)*)*)$'
}

if [ ! -f "$bin" ] || [ ! -x "$bin" ]; then
  die "classifier not found: $bin"
fi

results="$work/results"
: > "$results"

run_synthetic() {
  local dir case name lane items got n=0 repo
  dir=$(cd "$synthetic" && pwd)
  verify_frozen "$(dirname "$dir")" "$(basename "$dir")"
  for case in "$dir"/*/; do
    case=${case%/}
    name=$(basename "$case")
    if [ ! -f "$case/expected" ] || [ ! -f "$case/setup.sh" ] || [ ! -f "$case/change.sh" ]; then
      die "incomplete case: $name"
    fi
    lane=$(awk '$1 == "lane" { print $2; exit }' "$case/expected")
    items=$(awk '$1 == "items" { print $2; exit }' "$case/expected")
    valid_label "$lane" "$items" || die "invalid labels in $name/expected"
    n=$((n + 1))
    repo="$work/case$n"
    mkdir "$repo"
    (
      cd "$repo" || exit 1
      git init -q . &&
        git config user.name Corpus &&
        git config user.email corpus@example.com &&
        git config commit.gpgsign false &&
        git config core.autocrlf false &&
        bash "$case/setup.sh" || exit 1
      if [ -f "$case/risk-map.conf" ]; then
        mkdir -p .overdrive && cp "$case/risk-map.conf" .overdrive/risk-map.conf || exit 1
      fi
      git add -A && git commit -q --allow-empty -m baseline && bash "$case/change.sh"
    ) >"$work/case.log" 2>&1 || die "case $name failed to build: $(tail -n 3 "$work/case.log")"
    got=$(classify "$repo" --worktree)
    printf '%s\t%s\t%s\t%s\n' "$name" "$lane" "$(normalize_items "$items")" "$got" >> "$results"
    rm -rf "$repo"
  done
  [ "$n" -gt 0 ] || die "no cases in $synthetic"
}

# ensure_commit GITDIR REPO SHA fetches the commit (no blobs) when the cache lacks it.
ensure_commit() {
  git -C "$1" cat-file -e "$3^{commit}" 2>/dev/null && return 0
  git -C "$1" fetch -q --filter=blob:none origin "$3" >/dev/null 2>&1 ||
    die "cannot fetch $3 from $2"
}

run_tsv() {
  local tsv_dir line_no=0 repo sha lane items name got gitdir parents range n=0 empty
  tsv_dir=$(cd "$(dirname "$tsv")" && pwd)
  verify_frozen "$tsv_dir" "$(basename "$tsv")"
  mkdir -p "$cache" || die "cannot create $cache"
  cache=$(cd "$cache" && pwd)
  tr -d '\r' < "$tsv" > "$work/rows"
  while IFS="$(printf '\t')" read -r repo sha lane items _ || [ -n "$repo" ]; do
    line_no=$((line_no + 1))
    case $repo in '' | '#'*) continue ;; esac
    if ! printf '%s\n' "$sha" | grep -Eq '^[0-9a-f]{40}([0-9a-f]{24})?$' ||
      ! printf '%s\n' "$repo" | grep -Eq '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$' ||
      ! valid_label "$lane" "$items"; then
      die "malformed row at $tsv:$line_no"
    fi
    name=${repo#*/}
    gitdir="$cache/$name.git"
    if [ ! -d "$gitdir" ]; then
      git clone -q --bare --filter=blob:none --no-tags "$remote/$repo.git" "$gitdir" >/dev/null 2>&1 ||
        die "cannot clone $remote/$repo.git"
    fi
    ensure_commit "$gitdir" "$repo" "$sha"
    parents=$(git -C "$gitdir" rev-list --parents -n 1 "$sha" | awk '{ print NF - 1 }')
    case $parents in
      0)
        empty=$(git -C "$gitdir" hash-object -t tree --stdin </dev/null) || die "cannot hash the empty tree"
        range="$empty..$sha"
        ;;
      1) range="$sha^..$sha" ;;
      *) range="$sha^1..$sha" ;;
    esac
    n=$((n + 1))
    got=$(classify "$gitdir" --diff "$range")
    printf '%s\t%s\t%s\t%s\n' "$repo@$(printf '%s' "$sha" | cut -c1-12)" "$lane" \
      "$(normalize_items "$items")" "$got" >> "$results"
  done < "$work/rows"
  [ "$n" -gt 0 ] || die "no rows in $tsv"
}

if [ -n "$synthetic" ]; then
  run_synthetic
else
  run_tsv
fi

LC_ALL=C awk -F '\t' '
  function rank(l) { return l == "critical" ? 2 : l == "standard" ? 1 : l == "direct" ? 0 : -1 }
  function pct(a, b) { return b ? sprintf("%.2f", a / b) : "n/a" }
  {
    name = $1; el = $2; ei = $3; gl = $4; gi = $5
    if (rank(gl) < rank(el)) { status = "UNDER"; under++ }
    else if (rank(gl) > rank(el)) { status = "OVER"; over++ }
    else if (ei != gi) status = "ITEMS"
    else status = "PASS"
    printf "%s %s %s:%s %s:%s\n", status, name, el, ei, gl, gi
    if (el == "critical") { crit++; if (gl == "critical") crit_hit++ }
    else below++
    for (i in e) delete e[i]
    for (i in g) delete g[i]
    if (ei != "none") { k = split(ei, a, ","); for (i = 1; i <= k; i++) { e[a[i]] = 1; seen[a[i]] = 1 } }
    if (gi != "none") { k = split(gi, a, ","); for (i = 1; i <= k; i++) { g[a[i]] = 1; seen[a[i]] = 1 } }
    for (i in g) { if (i in e) tp[i]++; else fp[i]++ }
    for (i in e) if (!(i in g)) fn[i]++
  }
  END {
    recall = crit ? crit_hit / crit : 1
    rate = below ? over / below : 0
    line = sprintf("under=%d over=%d critical_recall=%.2f over_rate=%.2f", under, over, recall, rate)
    n = 0
    for (i in seen) names[++n] = i
    for (i = 2; i <= n; i++)
      for (j = i; j > 1 && names[j - 1] > names[j]; j--) { t = names[j]; names[j] = names[j - 1]; names[j - 1] = t }
    for (i = 1; i <= n; i++) {
      it = names[i]
      line = line sprintf(" item_precision.%s=%s item_recall.%s=%s", it, pct(tp[it] + 0, tp[it] + fp[it]), it, pct(tp[it] + 0, tp[it] + fn[it]))
    }
    print line
    exit (under > 0 || recall < 1 || rate > 0.25) ? 1 : 0
  }' "$results"
