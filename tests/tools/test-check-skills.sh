#!/usr/bin/env bash
# Tests for tools/check-skills.sh.

tool() { bash "$(dirname "$(dirname "$RUNNER")")/tools/check-skills.sh" "$@"; }

rep() { awk -v n="$2" -v c="$1" 'BEGIN { for (i = 0; i < n; i++) printf "%s", c }'; }

# mk_skill DIR NAME DESCRIPTION [EXTRA_FRONTMATTER]
mk_skill() {
  mkdir -p "$1/skills/$2"
  printf -- '---\nname: %s\ndescription: %s\n%s---\n\n# Title\n\nBody.\n' \
    "$2" "$3" "${4:+$4
}" > "$1/skills/$2/SKILL.md"
}

test_passes_valid_skill() {
  mk_skill p alpha "Use when a change needs a plan."
  tool p
}

test_empty_or_absent_skills_dir_passes() {
  mkdir -p p
  tool p
  mkdir -p p/skills
  tool p
}

test_rejects_long_description() {
  mk_skill p alpha "$(rep a 1025)" "disable-model-invocation: true"
  out=$(tool p 2>&1) && return 1
  assert_line "$out" "skills/alpha/SKILL.md: description longer than 1024 characters (1025)"
}

test_accepts_description_at_limit_when_hidden() {
  mk_skill p alpha "$(rep a 1024)" "disable-model-invocation: true"
  tool p
}

test_rejects_model_visible_description_over_300() {
  mk_skill p alpha "$(rep a 301)"
  out=$(tool p 2>&1) && return 1
  assert_line "$out" "skills/alpha/SKILL.md: model-visible description longer than 300 characters (301)"
}

test_rejects_angle_brackets() {
  mk_skill p alpha "Use when <x> happens."
  out=$(tool p 2>&1) && return 1
  assert_line "$out" "skills/alpha/SKILL.md: description contains < or >"
}

test_rejects_first_person_description() {
  mk_skill p alpha "I help with plans."
  out=$(tool p 2>&1) && return 1
  assert_line "$out" "skills/alpha/SKILL.md: description must be third person (starts with \"I \")"
  mk_skill q beta "You should plan."
  out=$(tool q 2>&1) && return 1
  assert_line "$out" "skills/beta/SKILL.md: description must be third person (starts with \"You \")"
}

test_rejects_name_dir_mismatch() {
  mk_skill p alpha "Use when planning."
  sed 's/^name: alpha/name: other/' p/skills/alpha/SKILL.md > p/x && mv p/x p/skills/alpha/SKILL.md
  out=$(tool p 2>&1) && return 1
  assert_line "$out" "skills/alpha/SKILL.md: name \"other\" does not match directory \"alpha\""
}

test_rejects_invalid_name_pattern() {
  mk_skill p Bad_Name "Use when planning."
  out=$(tool p 2>&1) && return 1
  assert_line "$out" "skills/Bad_Name/SKILL.md: name \"Bad_Name\" does not match ^[a-z0-9]+(-[a-z0-9]+)*\$"
}

test_rejects_missing_description() {
  mkdir -p p/skills/alpha
  printf -- '---\nname: alpha\n---\nBody\n' > p/skills/alpha/SKILL.md
  out=$(tool p 2>&1) && return 1
  assert_line "$out" "skills/alpha/SKILL.md: description missing"
}

test_rejects_frontmatter_not_at_line_one() {
  mkdir -p p/skills/alpha
  printf '\n---\nname: alpha\ndescription: Use when x.\n---\nBody\n' > p/skills/alpha/SKILL.md
  out=$(tool p 2>&1) && return 1
  assert_line "$out" "skills/alpha/SKILL.md: frontmatter must start at line 1"
}

test_rejects_body_over_499_lines() {
  mk_skill p alpha "Use when planning."
  rep $'x\n' 499 >> p/skills/alpha/SKILL.md
  out=$(tool p 2>&1) && return 1
  assert_line "$out" "skills/alpha/SKILL.md: body has 503 lines (limit 499)"
}

test_rejects_file_over_20000_bytes() {
  mk_skill p alpha "Use when planning."
  rep 'x' 20001 >> p/skills/alpha/SKILL.md
  out=$(tool p 2>&1) && return 1
  assert_file_contains /dev/stdin 'larger than 20000 bytes' <<<"$out"
}

test_reference_without_toc_fails() {
  mk_skill p alpha "Use when planning."
  mkdir -p p/skills/alpha/references
  { printf '# Ref\n'; rep $'line\n' 120; } > p/skills/alpha/references/big.md
  out=$(tool p 2>&1) && return 1
  assert_line "$out" "skills/alpha/references/big.md: more than 100 lines without a table of contents in the first 15 lines"
}

test_reference_with_toc_passes() {
  mk_skill p alpha "Use when planning."
  mkdir -p p/skills/alpha/references
  { printf '# Ref\n\n## Contents\n\n'; rep $'line\n' 120; } > p/skills/alpha/references/big.md
  tool p
}

test_short_reference_needs_no_toc() {
  mk_skill p alpha "Use when planning."
  mkdir -p p/skills/alpha/references
  rep $'line\n' 100 > p/skills/alpha/references/small.md
  tool p
}

test_rejects_link_to_missing_reference() {
  mk_skill p alpha "Use when planning."
  printf 'See references/gone.md for details.\n' >> p/skills/alpha/SKILL.md
  out=$(tool p 2>&1) && return 1
  assert_line "$out" "skills/alpha/SKILL.md: links to missing references/gone.md"
}

test_existing_reference_link_passes() {
  mk_skill p alpha "Use when planning."
  mkdir -p p/skills/alpha/references
  printf 'short\n' > p/skills/alpha/references/there.md
  printf 'See references/there.md.\n' >> p/skills/alpha/SKILL.md
  tool p
}

test_folded_description_is_parsed() {
  mkdir -p p/skills/alpha
  printf -- '---\nname: alpha\ndescription: >\n  Use when a change\n  needs a plan.\n---\nBody\n' > p/skills/alpha/SKILL.md
  tool p
  printf -- '---\nname: alpha\ndescription: >\n  Use when <a> change\n  needs a plan.\n---\nBody\n' > p/skills/alpha/SKILL.md
  out=$(tool p 2>&1) && return 1
  assert_line "$out" "skills/alpha/SKILL.md: description contains < or >"
}

test_reports_every_failure() {
  mk_skill p alpha "Use <x>."
  mk_skill p beta "You do."
  out=$(tool p 2>&1) && return 1
  assert_line "$out" "skills/alpha/SKILL.md: description contains < or >"
  assert_line "$out" "skills/beta/SKILL.md: description must be third person (starts with \"You \")"
}
