#!/usr/bin/env bash
# Tests for tools/check-budget.sh.

tool() { bash "$(dirname "$(dirname "$RUNNER")")/tools/check-budget.sh" "$@"; }

rep() { C=$1 awk -v n="$2" 'BEGIN { for (i = 0; i < n; i++) printf "%s", ENVIRON["C"] }'; }

# session_start PLUGIN TEXT: a hook that emits TEXT as SessionStart context.
session_start() {
  mkdir -p "$1/hooks"
  printf '%s' "$2" > "$1/hooks/context.txt"
  cat > "$1/hooks/session-start" <<'HOOK'
#!/usr/bin/env bash
dir=$(cd "$(dirname "$0")" && pwd)
printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$(cat "$dir/context.txt")"
HOOK
  chmod +x "$1/hooks/session-start"
}

skill() { # PLUGIN NAME DESCRIPTION [EXTRA]
  mkdir -p "$1/skills/$2"
  printf -- '---\nname: %s\ndescription: %s\n%s---\nBody\n' "$2" "$3" "${4:+$4
}" > "$1/skills/$2/SKILL.md"
}

agent() { # PLUGIN NAME DESCRIPTION
  mkdir -p "$1/agents"
  printf -- '---\nname: %s\ndescription: %s\nmodel: sonnet\n---\nBody\n' "$2" "$3" > "$1/agents/$2.md"
}

test_budget_counts_only_model_visible() {
  session_start p "$(rep a 70)"
  skill p alpha "$(rep d 20)"
  skill p hidden "$(rep h 3000)" "disable-model-invocation: true"
  agent p agent "$(rep e 5)"
  out=$(tool p)
  # 70 chars -> 20 tokens; (5 + 20) + (5 + 5) = 35 chars -> 10 tokens
  assert_line "$out" "injection_tokens=20 descriptions_tokens=10"
}

test_budget_counts_when_to_use() {
  session_start p "x"
  skill p alpha "$(rep d 20)" "when_to_use: $(rep w 10)"
  out=$(tool p)
  # 5 + 20 + 10 = 35 chars -> 10 tokens
  assert_line "$out" "injection_tokens=1 descriptions_tokens=10"
}

test_budget_counts_characters_not_bytes() {
  session_start p "ñññññññ"
  out=$(tool p)
  # 7 characters (14 bytes) -> 2 tokens
  assert_line "$out" "injection_tokens=2 descriptions_tokens=0"
}

test_budget_rounds_up() {
  session_start p "$(rep a 8)"
  out=$(tool p)
  assert_line "$out" "injection_tokens=3 descriptions_tokens=0"
}

test_budget_fails_over_limit() {
  session_start p "$(rep a 4000)"
  out=$(tool p 2>&1) && return 1
  assert_line "$out" "injection_tokens=1143 descriptions_tokens=0"
  assert_file_contains /dev/stdin 'injection over budget' <<<"$out"
}

test_budget_boundary_is_inclusive() {
  session_start p "$(rep a 3500)"
  out=$(tool p)
  assert_line "$out" "injection_tokens=1000 descriptions_tokens=0"
  session_start q "$(rep a 3501)"
  assert_exit 1 tool q
}

test_budget_fails_when_descriptions_over_limit() {
  session_start p "x"
  # 4200 chars -> 1200 tokens passes, 4201 -> 1201 fails
  skill p alpha "$(rep d 4195)"
  out=$(tool p)
  assert_line "$out" "injection_tokens=1 descriptions_tokens=1200"
  skill p alpha "$(rep d 4196)"
  assert_exit 1 tool p
}

test_budget_without_session_start_reports_zero() {
  skill p alpha "$(rep d 20)"
  out=$(tool p)
  assert_line "$out" "injection_tokens=0 descriptions_tokens=$(((25 * 2 + 6) / 7))"
  assert_file_contains /dev/stdin 'hooks/session-start not found' <<<"$out"
}

test_budget_missing_claude_cli_does_not_fail() {
  session_start p "x"
  PATH=$(dirname "$(command -v bash)"):/usr/bin:/bin tool p
}

test_budget_hook_failure_fails() {
  mkdir -p p/hooks
  printf '#!/usr/bin/env bash\nexit 3\n' > p/hooks/session-start
  chmod +x p/hooks/session-start
  assert_exit 1 tool p
}
