#!/usr/bin/env bash
# Tests for tools/evals/split-trigger-set.sh.

tool() { bash "$(dirname "$(dirname "$RUNNER")")/tools/evals/split-trigger-set.sh" "$@"; }

# trigger_case DIR NAME [FRONTMATTER LINES...]
trigger_case() {
  local dir=$1 name=$2
  shift 2
  mkdir -p "$dir/$name"
  {
    printf -- '---\nmax_turns: 3\n'
    if [ "$#" -gt 0 ]; then printf '%s\n' "$@"; fi
    printf -- '---\nFix the failing parser test.\n'
  } > "$dir/$name/prompt.md"
}

tags_of() { sed -n 's/^tags: //p' "$1/$2/prompt.md"; }

test_split_is_stable_and_60_40() {
  local i train=0
  for i in $(seq 1 100); do trigger_case set "tdd-trigger-$i"; done
  tool set > /dev/null
  for i in $(seq 1 100); do
    case $(tags_of set "tdd-trigger-$i") in
      '[train]') train=$((train + 1)) ;;
      '[validation]') ;;
      *) echo "unexpected tags for tdd-trigger-$i: $(tags_of set "tdd-trigger-$i")" >&2; return 1 ;;
    esac
  done
  [ "$train" -ge 54 ] && [ "$train" -le 66 ] || { echo "train count $train outside 60 +- 6" >&2; return 1; }
  cksum set/*/prompt.md > before
  tool set > /dev/null
  cksum set/*/prompt.md > after
  assert_eq "$(cat before)" "$(cat after)" "second run changes nothing"
}

test_split_assignment_depends_only_on_the_name() {
  trigger_case a tdd-trigger-bugfix
  trigger_case b/deeper tdd-trigger-bugfix
  tool a > /dev/null
  tool b > /dev/null
  assert_eq "[validation]" "$(tags_of a tdd-trigger-bugfix)"
  assert_eq "[validation]" "$(tags_of b/deeper tdd-trigger-bugfix)"
  trigger_case a tdd-trigger-plain
  tool a > /dev/null
  assert_eq "[train]" "$(tags_of a tdd-trigger-plain)"
}

test_split_keeps_existing_tags() {
  trigger_case set tdd-trigger-plain 'tags: [tdd-trigger, smoke]'
  tool set > /dev/null
  assert_eq "[tdd-trigger, smoke, train]" "$(tags_of set tdd-trigger-plain)"
}

test_split_replaces_a_stale_bucket_tag() {
  trigger_case set tdd-trigger-bugfix 'tags: [validation-draft, train]'
  tool set > /dev/null
  assert_eq "[validation-draft, validation]" "$(tags_of set tdd-trigger-bugfix)"
}

test_split_leaves_body_and_other_fields_alone() {
  trigger_case set tdd-trigger-plain 'allowed_tools: [Skill]'
  printf 'tags: not part of the front matter\n' >> set/tdd-trigger-plain/prompt.md
  tool set > /dev/null
  assert_file_contains set/tdd-trigger-plain/prompt.md '^allowed_tools: \[Skill\]$'
  assert_file_contains set/tdd-trigger-plain/prompt.md '^max_turns: 3$'
  assert_file_contains set/tdd-trigger-plain/prompt.md '^tags: not part of the front matter$'
  assert_eq "1" "$(grep -c '^Fix the failing parser test\.$' set/tdd-trigger-plain/prompt.md)"
}

test_split_rejects_block_style_tags() {
  trigger_case set tdd-trigger-plain 'tags:' '  - smoke'
  assert_exit 1 tool set
}

test_split_requires_a_directory() {
  assert_exit 64 tool
  assert_exit 1 tool missing
}
