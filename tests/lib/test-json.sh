#!/usr/bin/env bash
# shellcheck disable=SC2016
# Tests for plugins/overdrive/lib/json.sh.

load_json() { . "$(dirname "$(dirname "$RUNNER")")/plugins/overdrive/lib/json.sh"; }

test_json_get_string_escapes() {
  load_json
  local got
  got=$(printf '%s' '{"tool_input":{"file_path":"a \"q\" \\\\b\\/c"}}' | json_get_string file_path)
  assert_eq 'a "q" \\b\/c' "$got"
  got=$(printf '%s' '{"k":"a \"q\" \\b\/c"}' | json_get_string k)
  assert_eq 'a "q" \b/c' "$got"
  # Empty text between escaped quotes, next to escaped backslashes and controls.
  json_extract_string k '{"k":"a\"\"b\\\"\\n\t\"\""}'
  assert_eq 'a""b\"\n'$'\t''""' "$JSON_VALUE"
}

test_json_get_string_control_escapes() {
  load_json
  local got
  got=$(printf '%s' '{"k":"l1\nl2\tt\r"}' | json_get_string k; printf x)
  assert_eq $'l1\nl2\tt\rx' "$got"
}

test_json_get_string_backslash_before_quote() {
  load_json
  # The value ends in an escaped backslash, so the next quote closes it.
  local got
  got=$(printf '%s' '{"a":"x\\","b":"y"}' | json_get_string b)
  assert_eq y "$got"
  got=$(printf '%s' '{"a":"x\\","b":"y"}' | json_get_string a)
  assert_eq 'x'"\\" "$got"
}

test_json_get_string_nested_first() {
  load_json
  local got
  got=$(printf '%s' '{"a":{"file_path":"inner"},"file_path":"outer"}' | json_get_string file_path)
  assert_eq inner "$got"
}

test_json_get_string_skips_key_inside_value() {
  load_json
  local got
  got=$(printf '%s' '{"content":"say \"file_path\":\"fake\" now","file_path":"real"}' | json_get_string file_path)
  assert_eq real "$got"
  got=$(printf '%s' '{"content":"\"file_path\":\"fake\""}' | json_get_string file_path) && return 1
  assert_eq "" "$got"
}

test_json_get_string_whitespace_and_pretty() {
  load_json
  local got
  got=$(printf '{\n  "cwd" :\n  "/a b/c"\n}\n' | json_get_string cwd)
  assert_eq '/a b/c' "$got"
}

test_json_get_string_missing_and_non_string() {
  load_json
  assert_exit 1 json_get_string nope <<< '{"a":"b"}'
  assert_exit 1 json_get_string a <<< '{"a":1}'
  assert_exit 1 json_get_string a <<< '{"a":"unterminated'
  assert_exit 1 json_get_string a <<< ''
  local got
  got=$(printf '%s' '{"a":1,"b":{"a":"later"}}' | json_get_string a)
  assert_eq later "$got"
}

test_json_get_string_empty_value_succeeds() {
  load_json
  local got
  got=$(printf '%s' '{"a":""}' | json_get_string a)
  assert_eq "" "$got"
  json_get_string a <<< '{"a":""}' > /dev/null
}

test_json_get_string_unicode_escapes() {
  load_json
  local got
  # ASCII escapes decode to the character.
  got=$(printf '%s' '{"k":"a\u0041\u0022\u005c"}' | json_get_string k)
  assert_eq 'aA"'"\\" "$got"
  # Non-ASCII escapes decode to UTF-8, including surrogate pairs.
  got=$(printf '%s' '{"k":"p\u00e1ginas \u20ac \ud83d\ude00"}' | json_get_string k)
  assert_eq 'páginas € 😀' "$got"
  # Malformed escapes pass through unchanged.
  got=$(printf '%s' '{"k":"\u12zz|\ud83d"}' | json_get_string k)
  assert_eq '\u12zz|\ud83d' "$got"
}

test_json_get_string_raw_utf8_passthrough() {
  load_json
  local got
  got=$(printf '%s' '{"file_path":"apps/web/src/app/páginas legales/page.tsx"}' | json_get_string file_path)
  assert_eq 'apps/web/src/app/páginas legales/page.tsx' "$got"
}

test_json_get_string_argument_input_and_value_var() {
  load_json
  json_extract_string cwd '{"cwd":"/x"}'
  assert_eq /x "$JSON_VALUE"
  local got
  got=$(json_get_string cwd '{"cwd":"/y"}')
  assert_eq /y "$got"
  json_extract_string zzz '{"cwd":"/x"}' && return 1
  assert_eq "" "$JSON_VALUE"
}

test_json_get_string_large_input() {
  load_json
  local filler big
  filler=$(printf 'line \\"q\\" \\\\ \\n %.0s' 1 2 3 4 5 6 7 8 9 10)
  big=
  for _ in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do big=$big$filler$filler$filler$filler; done
  local got
  got=$(printf '{"content":"%s","file_path":"/z"}' "$big" | json_get_string file_path)
  assert_eq /z "$got"
}

test_json_get_bool() {
  load_json
  local got
  got=$(printf '%s' '{"a":true,"b":false,"c":"true"}' | json_get_bool a)
  assert_eq true "$got"
  got=$(printf '%s' '{"a":true,"b":false}' | json_get_bool b) || true
  assert_eq false "$got"
  json_get_bool a <<< '{"a":true}' > /dev/null
  assert_exit 1 json_get_bool b <<< '{"b":false}'
  assert_exit 1 json_get_bool c <<< '{"c":"true"}'
  assert_exit 1 json_get_bool d <<< '{"a":true}'
  got=$(printf '%s' '{"s":"x \"stop_hook_active\":true","stop_hook_active":false}' | json_get_bool stop_hook_active) || true
  assert_eq false "$got"
}

test_json_escape() {
  load_json
  local got
  got=$(json_escape 'a "q" \b'$'\n''c'$'\t''d')
  assert_eq 'a \"q\" \\b\nc\td' "$got"
  json_escape plain > /dev/null
}

# timed BOUND_LINUX BOUND_MAC CMD...: run CMD and fail if it is slower than the bound.
# Windows only gets a loose bound because process creation there is slow. CMD runs
# in a background subshell under a watchdog, so a regression fails within seconds
# instead of hanging the job.
timed() {
  local linux=$1 mac=$2 bound t limit
  shift 2
  case $OSTYPE in
    darwin*) bound=$mac ;;
    msys* | cygwin*) bound=10 ;;
    *) bound=$linux ;;
  esac
  limit=${bound%.*}
  limit=$(((${limit:-0} + 1) * 5))
  TIMEFORMAT=%R
  t=$( { time watchdog "$limit" "$@"; } 2>&1 > /dev/null) || {
    echo "killed after $limit s: $1 ${2:0:40}" >&2
    return 1
  }
  echo "timing: $t s (bound $bound s): $1 ${2:0:40}" >&2
  awk -v t="$t" -v b="$bound" 'BEGIN { exit !(t + 0 < b + 0) }' || {
    echo "too slow: $t s >= $bound s" >&2
    return 1
  }
}

# watchdog SECONDS CMD...: run CMD, killing it after SECONDS. Fails only when killed;
# CMD's own exit status is ignored because lookups of absent keys return 1.
watchdog() {
  local limit=$1 pid killer rc
  shift
  "$@" > /dev/null 2>&1 &
  pid=$!
  (sleep "$limit" && kill -9 "$pid") > /dev/null 2>&1 &
  killer=$!
  wait "$pid"
  rc=$?
  kill "$killer" 2> /dev/null
  wait "$killer" 2> /dev/null
  [ "$rc" -ne 137 ]
}

# big_payload KIND: print a ~200 KB hook-like payload with the interesting key last.
big_payload() {
  local chunk filler i=0
  case $1 in
    plain) chunk='lorem ipsum dolor sit amet, consectetur adipiscing elit 0123456789 ' ;;
    escaped) chunk='say \"hi\" \\ path\\to\\file \n and \t more \u00e1 text and then some plain words to widen the gap between escaped quotes in this chunk of text ' ;;
  esac
  filler=$chunk$chunk$chunk$chunk$chunk$chunk$chunk$chunk
  filler=$filler$filler$filler$filler$filler$filler$filler$filler
  filler=$filler$filler$filler$filler
  while [ "${#filler}" -lt 200000 ]; do filler=$filler$filler; done
  printf '{"tool_name":"Edit","tool_input":{"new_string":"%s","file_path":"/z/last.ts"}}' "$filler"
}

test_json_large_payload_key_after_big_value() {
  load_json
  local kind payload
  for kind in plain escaped; do
    payload=$(big_payload "$kind")
    [ "${#payload}" -ge 200000 ]
    timed 0.3 1 json_extract_string file_path "$payload"
    json_extract_string file_path "$payload"
    assert_eq /z/last.ts "$JSON_VALUE"
  done
}

test_json_large_payload_absent_key() {
  load_json
  local kind payload
  for kind in plain escaped; do
    payload=$(big_payload "$kind")
    timed 0.3 1 json_extract_string nothere "$payload"
    if json_extract_string nothere "$payload"; then return 1; fi
    timed 0.3 1 json_get_bool nothere "$payload"
    if json_get_bool nothere "$payload" > /dev/null; then return 1; fi
  done
}

test_json_large_value_decodes_quickly() {
  load_json
  local kind payload
  for kind in plain escaped; do
    payload=$(big_payload "$kind")
    timed 1 5 json_extract_string new_string "$payload"
    json_extract_string new_string "$payload"
    [ "${#JSON_VALUE}" -ge 100000 ]
  done
  json_extract_string new_string "$(big_payload escaped)"
  case $JSON_VALUE in 'say "hi" \ path\to\file '$'\n'' and '$'\t'' more á text '*) ;; *) echo "bad decode" >&2; return 1 ;; esac
}

test_json_long_backslash_runs_stay_linear() {
  load_json
  local bs payload
  bs="\\\\\\\\"
  bs=$bs$bs$bs$bs$bs$bs$bs$bs
  while [ "${#bs}" -lt 200000 ]; do bs=$bs$bs; done
  # 200 KB of escaped backslashes, then a fake key behind an odd run of backslashes.
  payload="{\"cmd\":\"$bs\",\"a\":\"$bs\\\"k\\\":\\\"no\",\"k\":\"v\"}"
  timed 0.3 1 json_extract_string k "$payload"
  json_extract_string k "$payload"
  assert_eq v "$JSON_VALUE"
  timed 1 5 json_extract_string cmd "$payload"
  json_extract_string cmd "$payload"
  [ "${#JSON_VALUE}" -eq $((${#bs} / 2)) ]
  case $JSON_VALUE in *[!\\]*) echo "decoded value is not all backslashes" >&2; return 1 ;; esac
  timed 1 5 json_extract_string a "$payload"
  json_extract_string a "$payload"
  assert_eq '\"k":"no' "${JSON_VALUE: -8}"
}

test_json_many_small_strings_stay_linear() {
  load_json
  local json='[' i
  for i in 1 2 3 4 5 6 7 8 9 10; do json=$json'"aa","bb","cc","dd","ee","ff","gg","hh","ii","jj",'; done
  for i in 1 2 3 4 5 6 7 8 9 10 11 12; do json=$json$json; done
  json=$json'{"k":"v"}]'
  [ "${#json}" -gt 400000 ]
  timed 1 3 json_extract_string k "$json"
  json_extract_string k "$json"
  assert_eq v "$JSON_VALUE"
}

test_json_escape_control_characters() {
  load_json
  local got s='' i h c
  got=$(json_escape $'\b\f\001\037')
  assert_eq '\u0008\u000c\u0001\u001f' "$got"
  # Through a variable: a CR written inline in a command substitution is dropped by Git Bash.
  s=$'a\tb\nc\rd'
  got=$(json_escape "$s")
  case $got in *[[:cntrl:]]*) echo "raw control character left in output" >&2; return 1 ;; esac
  case $got in 'a\tb\nc'?'rd') ;; *) echo "bad escape: $got" >&2; return 1 ;; esac
  case $got in *'\r'*) ;; *) echo "missing escaped CR in: $got" >&2; return 1 ;; esac
  s=''
  # Every C0 control survives a round trip through the extractor.
  for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31; do
    printf -v h '%02x' "$i"
    # shellcheck disable=SC2059
    printf -v c "\\x$h"
    s=$s$c
  done
  got=$(json_escape "$s")
  case $got in *[[:cntrl:]]*) echo "raw control character left in output" >&2; return 1 ;; esac
  json_extract_string k "{\"k\":\"$got\"}"
  assert_eq "$s" "$JSON_VALUE"
}

test_json_escape_large_input_stays_linear() {
  load_json
  local unit big='' want='' esc i
  unit=$'say "hi" \\ path\\to\\file\nnext\tcol\r\001\037 plain words '
  esc=$(json_escape "$unit")
  for i in 1 2 3 4 5 6 7 8; do big=$big$unit$unit$unit$unit; want=$want$esc$esc$esc$esc; done
  for i in 1 2 3 4 5 6 7; do big=$big$big; want=$want$want; done
  [ "${#big}" -gt 150000 ]
  timed 2 5 json_escape "$big"
  [ "$(json_escape "$big")" = "$want" ] || { echo "large escape differs from the small one" >&2; return 1; }
  json_extract_string k "{\"k\":\"$want\"}"
  [ "$JSON_VALUE" = "$big" ] || { echo "round trip differs" >&2; return 1; }
}

# key_flood: ~15k real key occurrences and key-named string values before the real one.
key_flood() {
  local unit='{"file_path":null},{"file_path":{"a":1}},["file_path","file_path"],' json='[' i
  for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14; do json=$json$unit$unit$unit$unit$unit$unit$unit$unit; done
  json=$json$json$json$json$json$json$json$json$json$json$json$json$json$json$json$json$json$json$json$json$json$json$json$json$json
  printf '%s{"file_path":"/z/real.ts"}]' "$json"
}

test_json_repeated_key_occurrences_stay_linear() {
  load_json
  local payload
  payload=$(key_flood)
  [ "${#payload}" -gt 150000 ]
  timed 1 3 json_extract_string file_path "$payload"
  json_extract_string file_path "$payload"
  assert_eq /z/real.ts "$JSON_VALUE"
  timed 1 3 json_extract_string absent_key "$payload"
}

test_json_match_at_many_offsets_and_shapes() {
  load_json
  local pad n spaces
  spaces=$(printf '%400s' '')
  for n in 230 240 245 250 252 254 255 256 257 258 260 270 511 512 513 1023 1024 1025; do
    pad=$(printf '%*s' "$n" '' | tr ' ' x)
    json_extract_string file_path "{\"a\":\"$pad\",\"file_path\":\"ok$n\"}"
    assert_eq "ok$n" "$JSON_VALUE"
    json_extract_string file_path "{\"a\":\"$pad\",\"file_path\" :$spaces\"w$n\"}"
    assert_eq "w$n" "$JSON_VALUE"
    json_extract_string file_path "{\"a\":\"$pad\\\"file_path\\\":\\\"fake\\\"\",\"file_path\":\"real$n\"}"
    assert_eq "real$n" "$JSON_VALUE"
  done
}

test_json_whitespace_before_the_colon_and_value() {
  load_json
  local sp tab nl
  sp=$(printf '%200s' '')
  tab=$(printf '\t%.0s' $(seq 200))
  nl=$(printf '\n%.0s' $(seq 200))
  json_extract_string cmd "{\"cmd\"$sp:\"V1\"}"
  assert_eq V1 "$JSON_VALUE"
  json_extract_string cmd "{\"cmd\"$tab:$tab\"V2\"}"
  assert_eq V2 "$JSON_VALUE"
  json_extract_string cmd "{\"cmd\"$nl:$nl\"V3\"}"
  assert_eq V3 "$JSON_VALUE"
}

test_json_key_text_inside_values_and_at_the_end() {
  load_json
  json_extract_string k '{"a":"x \"k\":\"no\" y","b":["k","k"],"k":"yes"}'
  assert_eq yes "$JSON_VALUE"
  json_extract_string k '{"k":"a \"k\":\"b\" c"}'
  assert_eq 'a "k":"b" c' "$JSON_VALUE"
  json_extract_string k '{"a":1,"k":"end"}'
  assert_eq end "$JSON_VALUE"
  if json_extract_string k '{"a":"k","k"'; then return 1; fi
  [ -z "$JSON_VALUE" ]
}

test_json_nested_value_is_skipped_to_the_next_key() {
  load_json
  json_extract_string k '{"k":{"x":"not me"},"y":[{"k":null}],"k":"found"}'
  assert_eq found "$JSON_VALUE"
  json_extract_string k '{"k":["a","b"],"z":{"k":"inner"}}'
  assert_eq inner "$JSON_VALUE"
}

test_json_raw_control_characters_in_input_do_not_break_lookup() {
  load_json
  local c
  # \001 and \177 are the bytes bash uses internally to quote expansions.
  for c in $'\037' $'\036' $'\035' $'\001' $'\177'; do
    json_extract_string k "{\"a\":\"p${c}q\",\"k\":\"ok\"}"
    assert_eq ok "$JSON_VALUE"
  done
}

test_json_extract_strings_matches_single_lookups() {
  load_json
  local doc k i want
  local -a docs=(
    '{"session_id":"s1","cwd":"/a b/á","tool_name":"Edit","tool_input":{"file_path":"C:\\x\\\"q\".ts","old_string":"\"cwd\": \"no\""}}'
    '{"a":{"cwd":"inner"},"cwd":"outer","tool_name":7,"x":"tool_name","tool_name":"Bash"}'
    '{"k":"a\"cwd\":\"x\"","cwd" : "y" ,"session_id":"\u00e9\n"}'
    '{"a":"x\\","cwd":"z","tool_name":"","session_id":"\\\\"}'
    '{ "cwd": {"cwd": 1}, "tool_name": true }'
    'not json'
  )
  for doc in "${docs[@]}"; do
    json_extract_strings "$doc" tool_name cwd session_id missing
    i=0
    for k in tool_name cwd session_id missing; do
      if json_extract_string "$k" "$doc"; then
        want=set:$JSON_VALUE
      else
        want='unset'
      fi
      if [ -n "${JSON_VALUES[i]+x}" ]; then
        assert_eq "$want" "set:${JSON_VALUES[i]}" "$k in $doc"
      else
        assert_eq "$want" unset "$k in $doc"
      fi
      i=$((i + 1))
    done
  done
}

test_json_extract_strings_stops_early_on_large_input() {
  load_json
  local big doc t0 t1
  big=$(printf '"x\\" %.0s' $(seq 20000))
  doc='{"session_id":"s","cwd":"/r","tool_name":"Write","tool_input":{"content":"'$big'","file_path":"/f"}}'
  t0=$SECONDS
  json_extract_strings "$doc" tool_name session_id cwd
  t1=$SECONDS
  assert_eq Write "${JSON_VALUES[0]}"
  assert_eq s "${JSON_VALUES[1]}"
  assert_eq /r "${JSON_VALUES[2]}"
  [ $((t1 - t0)) -le 2 ] || { echo "took $((t1 - t0)) s" >&2; return 1; }
}
