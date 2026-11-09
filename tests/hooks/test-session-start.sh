#!/usr/bin/env bash
# Tests for plugins/overdrive/hooks/session-start.

plugin_dir() { printf '%s\n' "$(dirname "$(dirname "$RUNNER")")/plugins/overdrive"; }

event='{"session_id":"s","cwd":"/nowhere","hook_event_name":"SessionStart","source":"startup"}'

# run_hook ROOT: run the hook the way Claude Code does, event on stdin, root in the environment.
run_hook() {
  printf '%s' "$event" | CLAUDE_PLUGIN_ROOT=$1 "$1/hooks/session-start"
}

# context_of JSON: set JSON_VALUE to the decoded additionalContext.
context_of() {
  # shellcheck source=../../plugins/overdrive/lib/json.sh
  . "$(plugin_dir)/lib/json.sh"
  json_extract_string additionalContext "$1"
}

# A pure-shell structural check: outside strings, braces balance and every string closes.
json_balanced() {
  LC_ALL=C awk '
    { text = text (NR > 1 ? "\n" : "") $0 }
    END {
      depth = 0; instr = 0; esc = 0
      for (i = 1; i <= length(text); i++) {
        c = substr(text, i, 1)
        if (instr) {
          if (esc) esc = 0
          else if (c == "\\") esc = 1
          else if (c == "\"") instr = 0
          else if (c == "\n" || c == "\t" || c == "\r") exit 1
        } else if (c == "\"") instr = 1
        else if (c == "{") depth++
        else if (c == "}") { depth--; if (depth < 0) exit 1 }
      }
      exit (depth != 0 || instr)
    }' <<<"$1"
}

assert_valid_json() {
  json_balanced "$1" || { printf 'unbalanced JSON: %s\n' "$1" >&2; return 1; }
  if command -v python3 >/dev/null 2>&1; then
    printf '%s' "$1" | python3 -m json.tool >/dev/null
  fi
}

# fake_plugin DIR CORE: the real hook and JSON library with CORE as the router text.
fake_plugin() {
  mkdir -p "$1/hooks" "$1/lib"
  cp "$(plugin_dir)/hooks/session-start" "$1/hooks/session-start"
  cp "$(plugin_dir)/lib/json.sh" "$1/lib/json.sh"
  chmod +x "$1/hooks/session-start"
  printf '%s' "$2" > "$1/hooks/core.md"
}

is_windows() {
  case $(uname -s) in MINGW* | MSYS* | CYGWIN*) return 0 ;; esac
  return 1
}

test_emits_valid_json() {
  local root out
  root=$(plugin_dir)
  out=$(run_hook "$root")
  assert_valid_json "$out"
  case $out in
    '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"'*'"}}') ;;
    *) printf 'unexpected shape: %s\n' "$out" >&2; return 1 ;;
  esac
}

test_emits_valid_json_outside_git() {
  local root out
  root=$(plugin_dir)
  mkdir plain
  cd plain || return 1
  out=$(printf '%s' "$event" | env -u CLAUDE_PROJECT_DIR CLAUDE_PLUGIN_ROOT="$root" GIT_CEILING_DIRECTORIES="$PWD/.." "$root/hooks/session-start")
  assert_valid_json "$out"
  context_of "$out"
  case $JSON_VALUE in *'overdrive risk'*) ;; *) echo "router missing" >&2; return 1 ;; esac
}

test_plugin_root_substituted() {
  local root out
  root=$(plugin_dir)
  out=$(run_hook "$root")
  context_of "$out"
  case $JSON_VALUE in *'{{'*) echo "placeholder left: $JSON_VALUE" >&2; return 1 ;; esac
  # The root is spelled out once, and both the CLI and the user-only skills hang off it.
  # shellcheck disable=SC2016  # backquotes are literal Markdown
  case $JSON_VALUE in
    *"R = \`$root\`"*'`R/bin/overdrive`'*'R/skills/<name>/SKILL.md'*) ;;
    *) echo "no absolute root for the CLI and the user-only skills" >&2; return 1 ;;
  esac
}

test_plugin_root_with_shell_specials_substituted() {
  local root out
  root="$PWD/pl ug&'in á"
  fake_plugin "$root" 'see {{PLUGIN_ROOT}}/skills/x/SKILL.md and {{PLUGIN_ROOT}}'
  out=$(run_hook "$root")
  assert_valid_json "$out"
  context_of "$out"
  assert_eq "see $root/skills/x/SKILL.md and $root" "$JSON_VALUE"
  # Quotes and backslashes cannot appear in Windows file names.
  is_windows && return 0
  root="$PWD/q\"b\\s&"
  fake_plugin "$root" '{{PLUGIN_ROOT}}/a'
  out=$(run_hook "$root")
  assert_valid_json "$out"
  context_of "$out"
  assert_eq "$root/a" "$JSON_VALUE"
}

test_escapes_quotes_and_newlines() {
  local core out want pad='' long='' _
  # Past 512 bytes json_escape switches to its split-and-join path; cover both.
  for _ in $(seq 100); do long="$long"'q"b\\s '; done
  for size in short long; do
    [ "$size" = short ] || pad=$long
    core=$(printf 'say "hi" \\ back\\slash\ttab\rcr\001ctl\n\n{{PLUGIN_ROOT}}\n%s\nend\n_' "$pad")
    core=${core%_}
    fake_plugin "$size" "$core"
    out=$(run_hook "$PWD/$size")
    assert_valid_json "$out"
    context_of "$out"
    want=$(printf 'say "hi" \\ back\\slash\ttab\rcr\001ctl\n\n%s\n%s\nend\n_' "$PWD/$size" "$pad")
    assert_eq "${want%_}" "$JSON_VALUE" "$size"
  done
  [ "${#core}" -gt 512 ] || { echo "long fixture is only ${#core} bytes" >&2; return 1; }
}

test_missing_core_still_valid_json() {
  local out rc=0
  fake_plugin p x
  rm p/hooks/core.md
  out=$(run_hook "$PWD/p") || rc=$?
  assert_eq 0 "$rc"
  assert_valid_json "$out"
  case $out in *systemMessage*) ;; *) echo "no notice: $out" >&2; return 1 ;; esac
}

test_runs_without_external_commands() {
  local root out
  root=$(plugin_dir)
  # Any external command (cat, sed, git) would fail to resolve.
  out=$(printf '%s' "$event" | CLAUDE_PLUGIN_ROOT=$root PATH=/nonexistent "$BASH" "$root/hooks/session-start" 2>&1)
  assert_valid_json "$out"
}

test_core_within_budget() {
  local root out chars tokens
  root=$(plugin_dir)
  out=$(run_hook "$root")
  context_of "$out"
  # shellcheck source=../../tools/lib/skillmeta.sh
  . "$(dirname "$(dirname "$RUNNER")")/tools/lib/skillmeta.sh"
  chars=$(printf '%s' "$JSON_VALUE" | char_count)
  tokens=$(((2 * chars + 6) / 7))
  echo "core: $chars chars, $tokens tokens"
  [ "$tokens" -le 1000 ] || { echo "core over budget: $tokens tokens" >&2; return 1; }
}

test_core_covers_routing_rules() {
  local root out
  root=$(plugin_dir)
  out=$(run_hook "$root")
  context_of "$out"
  for want in 'overdrive risk --intent' '--worktree' 'Risk: <lane> — <items | none>' \
    'Ruling: <what> — <why> — <cost if wrong>' 'direct' 'standard' 'critical' \
    'Questions and explanations are read-only' '--diff <base>...HEAD' '--repo' \
    'irreversible actions, destructive actions, the user'"'"'s accounts, money or secrets, a product decision only the user can make' \
    'If you were dispatched with a brief, follow the brief instead of this routing.' \
    'A reply that says work is done or ready, gives a go-ahead or status line, relays a report, or answers yes/no about a vendor, price or law first loads overdrive:evidence-based-verification, in every lane;' \
    "a direct change's own done line is verified inline instead." \
    'answer, then stop without offering to make or plan the change.' \
    'Above direct, call the Skill tool for each matching overdrive:<name> before its step' \
    risk-triage intent-discovery decision-planning test-driven-development risk-scaled-execution \
    parallel-execution risk-scaled-review root-cause-debugging deep-research decision-log \
    compound-learning evidence-based-verification release-gates skill-evaluation; do
    case $JSON_VALUE in
      *"$want"*) ;;
      *) printf 'core lacks: %s\n' "$want" >&2; return 1 ;;
    esac
  done
}

test_latency_p95_under_30ms() {
  local root _ b t0 t1 times p95 best=''
  # A shared developer machine is too noisy for a wall-clock budget.
  if [ -z "${CI:-}" ] || [ "$(uname -s)" != Linux ]; then
    echo "notice: latency budget is asserted on Linux CI only; skipped"
    return 0
  fi
  if [ -z "${EPOCHREALTIME:-}" ]; then
    echo "notice: bash $BASH_VERSION has no EPOCHREALTIME; latency skipped"
    return 0
  fi
  root=$(plugin_dir)
  run_hook "$root" >/dev/null
  # Best of three batches of 50: a runner hiccup spoils one batch, not the verdict.
  for b in 1 2 3; do
    times=''
    for _ in $(seq 50); do
      t0=${EPOCHREALTIME/[.,]/}
      CLAUDE_PLUGIN_ROOT=$root "$root/hooks/session-start" <<<"$event" >/dev/null
      t1=${EPOCHREALTIME/[.,]/}
      times="$times$((t1 - t0))
"
    done
    # p95 of 50 samples is the 48th smallest.
    p95=$(printf '%s' "$times" | sort -n | sed -n 48p)
    echo "batch $b p95: ${p95} us"
    if [ -z "$best" ] || [ "$p95" -lt "$best" ]; then best=$p95; fi
  done
  [ "$best" -lt 30000 ] || { echo "best p95 ${best} us over 30 ms" >&2; return 1; }
}
