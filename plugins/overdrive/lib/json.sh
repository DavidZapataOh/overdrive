#!/usr/bin/env bash
# Minimal JSON string and boolean extraction for hook input. Sourced, never executed.
# Hot path: builtins and parameter expansion only, no forks (callers that want that
# must also avoid command substitution and use json_extract_* with JSON_VALUE).
# Key text inside a string value is never mistaken for a key. Object keys are
# compared raw, without decoding escapes.

if [ -n "${_OD_JSON_LOADED:-}" ]; then return 0; fi
_OD_JSON_LOADED=1

JSON_VALUE=
_JSON_RAW=
_JSON_BOOL=
_JSON_S=
_JSON_LEN=0
_JSON_POS=0
_JSON_N=0

# Lookup works on the text: find the next "KEY" and judge it. In valid JSON every quote
# inside a string is escaped, so a match whose opening quote follows an odd run of
# backslashes lies inside a string; an unescaped match followed by a colon is a real
# key. After a few rejected matches the text is split once on quotes and walked
# instead, so a flood of false matches costs one linear pass, not one search each.
#
# Bash computes the length of the remaining string for every candidate position of a
# pattern removal, which makes ${s%%x*}, ${s#*x}, ${s//x/y} and friends quadratic on
# large input (on bash 3.2 ${s//x/y} even costs O(length) per match). A glob test
# (case $s in *x*) is one linear pass, a substring costs one length computation, and
# read splits linearly, so only those touch the input. Bash 3.2 also walks an array
# from its head on every indexed read, so parts are visited with for-in.

# _json_index NEEDLE OFFSET: set _JSON_POS to the first NEEDLE at or after OFFSET in
# _JSON_S (length _JSON_LEN). Glob tests on doubling windows, then bisection; each
# test only covers text not ruled out yet (plus the needle length), so the cost is
# O(distance to the match).
_json_index() {
  local nd=$1 off=$2 rem lo=0 hi=64 mid k
  k=$((${#nd} - 1))
  rem=$((_JSON_LEN - off))
  # Invariant: no match ends at or before off+lo.
  while :; do
    [ "$hi" -le "$rem" ] || hi=$rem
    mid=$((lo > k ? lo - k : 0))
    case ${_JSON_S:off+mid:hi-mid} in *"$nd"*) break ;; esac
    [ "$hi" -lt "$rem" ] || return 1
    lo=$hi
    hi=$((hi * 2))
  done
  # The first match ends in (off+lo, off+hi].
  while [ $((hi - lo)) -gt 1 ]; do
    mid=$(((lo + hi) / 2))
    k=$((lo > ${#nd} - 1 ? lo - ${#nd} + 1 : 0))
    case ${_JSON_S:off+k:mid-k} in
      *"$nd"*) hi=$mid ;;
      *) lo=$mid ;;
    esac
  done
  _JSON_POS=$((off + hi - ${#nd}))
}

# _json_tail_run TEXT [END]: set _JSON_N to the number of backslashes that end TEXT,
# or its first END characters. Glob tests on doubling suffix windows, then bisection
# over the part not yet known, so the cost is O(run) plus one length per test.
_json_tail_run() {
  local q=$1 e=${2-} lo=0 hi=1 mid
  [ -n "$e" ] || e=${#q}
  # Invariant: the lo characters before e are backslashes.
  while :; do
    [ "$hi" -le "$e" ] || hi=$e
    case ${q:e-hi:hi-lo} in *[!\\]*) break ;; esac
    lo=$hi
    if [ "$hi" -ge "$e" ]; then
      _JSON_N=$e
      return 0
    fi
    hi=$((hi * 2))
  done
  # The run is shorter than hi.
  while [ $((hi - lo)) -gt 1 ]; do
    mid=$(((lo + hi) / 2))
    case ${q:e-mid:mid-lo} in
      *[!\\]*) hi=$mid ;;
      *) lo=$mid ;;
    esac
  done
  _JSON_N=$lo
}

# _json_odd_tail STRING: true when the quote right after STRING is escaped.
_json_odd_tail() {
  case $1 in *\\) ;; *) return 1 ;; esac
  _json_tail_run "$1"
  [ $((_JSON_N % 2)) -eq 1 ]
}

# _json_ws OFFSET: set _JSON_POS to the first non-whitespace offset of _JSON_S at or
# after OFFSET, looking at bounded windows so long runs stay cheap.
_json_ws() {
  local o=$1 w ws
  while :; do
    w=${_JSON_S:o:256}
    ws=${w%%[![:space:]]*}
    o=$((o + ${#ws}))
    [ "${#ws}" -eq 256 ] || break
  done
  _JSON_POS=$o
}

# _json_join START COUNT: set _JSON_RAW to COUNT parts of P from START joined by quotes.
_json_join() {
  printf -v _JSON_RAW '%s"' "${P[@]:$1:$2}"
  _JSON_RAW=${_JSON_RAW%\"}
}

# _json_body OFFSET: set _JSON_RAW to the raw body of the string that starts at OFFSET
# of _JSON_S (after its opening quote). Returns 1 when it never closes.
_json_body() {
  local p i=0 n
  local -a P=()
  _json_index '"' "$1" || return 1
  _JSON_RAW=${_JSON_S:$1:_JSON_POS-$1}
  _json_odd_tail "$_JSON_RAW" || return 0
  # Escaped quotes inside the value: split the rest once and stop at the closing quote.
  IFS='"' read -r -d '' -a P <<< "${_JSON_S:$1}" || true
  n=${#P[@]}
  for p in "${P[@]}"; do
    i=$((i + 1))
    # Most parts end in a single backslash or none, which a glob settles.
    case $p in
      *[!\\]\\ | \\) continue ;;
      *\\) ! _json_odd_tail "$p" || continue ;;
    esac
    # The here-string added a newline, so the last part is never followed by a quote.
    [ "$i" -lt "$n" ] || return 1
    _json_join 0 "$i"
    return 0
  done
  return 1
}

# _json_seek KEY JSON KIND: find the first KEY whose value is a string (KIND string,
# raw body left in _JSON_RAW) or a boolean (KIND bool, _JSON_BOOL). Keys are compared
# raw, so a KEY containing a quote or ending in an escape never matches.
_json_seek() {
  local LC_ALL=C rc
  _json_find "$@"
  rc=$?
  # Do not keep a copy of a large input alive in a global.
  _JSON_S=
  return "$rc"
}

_json_find() {
  local nd=\"$1\" off=0 pos tries=0
  case $2 in *"$nd"*) ;; *) return 1 ;; esac
  ! _json_odd_tail "$1" || return 1
  _JSON_S=$2
  _JSON_LEN=${#2}
  while [ "$tries" -lt 8 ]; do
    tries=$((tries + 1))
    _json_index "$nd" "$off" || return 1
    pos=$_JSON_POS
    off=$((pos + ${#nd}))
    _json_tail_run "$_JSON_S" "$pos"
    [ $((_JSON_N % 2)) -eq 0 ] || continue
    _json_ws "$off"
    [ "${_JSON_S:_JSON_POS:1}" = : ] || continue
    _json_ws $((_JSON_POS + 1))
    case $3:${_JSON_S:_JSON_POS:5} in
      string:\"*) _json_body $((_JSON_POS + 1)); return ;;
      bool:true*) _JSON_BOOL=true; return 0 ;;
      bool:false) _JSON_BOOL=false; return 0 ;;
    esac
  done
  _json_walk "$@"
}

# _json_walk KEY JSON KIND: same contract as _json_seek, by splitting the whole text on
# quotes once and walking the parts in order.
_json_walk() {
  local p v prev='' st=0 i=0 n start=0
  local -a P=()
  IFS='"' read -r -d '' -a P <<< "$2" || true
  n=${#P[@]}
  for p in "${P[@]}"; do
    i=$((i + 1))
    case $st in
      2)
        # Inside the value: it ends at the first part not followed by an escaped quote.
        case $p in
          *[!\\]\\ | \\) continue ;;
          *\\) ! _json_odd_tail "$p" || continue ;;
        esac
        break
        ;;
      1)
        # The text between the key's closing quote and the next quote.
        st=0
        v=$p
        case $v in [[:space:]]*) v=${v#"${v%%[![:space:]]*}"} ;; esac
        case $v in
          :*)
            v=${v#:}
            case $v in [[:space:]]*) v=${v#"${v%%[![:space:]]*}"} ;; esac
            case $3:$v in
              string:) st=2; start=$i; continue ;;
              bool:true*) _JSON_BOOL=true; return 0 ;;
              bool:false*) _JSON_BOOL=false; return 0 ;;
            esac
            ;;
        esac
        ;;
    esac
    case $p in
      "$1")
        case $prev in
          *\\) _json_odd_tail "$prev" || st=1 ;;
          *) [ "$i" -eq 1 ] || st=1 ;;
        esac
        ;;
    esac
    prev=$p
  done
  [ "$st" -eq 2 ] && [ "$i" -lt "$n" ] || return 1
  _json_join "$start" $((i - start))
}

# The \xHH escapes only work in the printf format, hence the disables below.
# _json_utf8 CODE: set _JSON_BYTES to the UTF-8 bytes of a code point >= 0x80.
_json_utf8() {
  local c=$1 b1 b2 b3 b4
  if [ "$c" -lt 2048 ]; then
    printf -v b1 '%02x' $((192 | (c >> 6)))
    printf -v b2 '%02x' $((128 | (c & 63)))
    # shellcheck disable=SC2059
    printf -v _JSON_BYTES "\\x$b1\\x$b2"
  elif [ "$c" -lt 65536 ]; then
    printf -v b1 '%02x' $((224 | (c >> 12)))
    printf -v b2 '%02x' $((128 | ((c >> 6) & 63)))
    printf -v b3 '%02x' $((128 | (c & 63)))
    # shellcheck disable=SC2059
    printf -v _JSON_BYTES "\\x$b1\\x$b2\\x$b3"
  else
    printf -v b1 '%02x' $((240 | (c >> 18)))
    printf -v b2 '%02x' $((128 | ((c >> 12) & 63)))
    printf -v b3 '%02x' $((128 | ((c >> 6) & 63)))
    printf -v b4 '%02x' $((128 | (c & 63)))
    # shellcheck disable=SC2059
    printf -v _JSON_BYTES "\\x$b1\\x$b2\\x$b3\\x$b4"
  fi
}

# _json_decode RAW: decode the escapes of a raw string body into JSON_VALUE.
# \uXXXX escapes decode to ASCII or UTF-8 (surrogate pairs included); a malformed or
# lone-surrogate escape is passed through as typed. NUL (\u0000) is dropped because a
# shell string cannot hold it. RAW is split on backslashes once, so each field after
# the first starts with the escape letter; an empty field is an escaped backslash,
# whose following field is literal text.
_json_decode() {
  local seg rest code h st='' m=1
  local -a segs=() o=()
  JSON_VALUE=
  case $1 in
    *\\*) ;;
    *) JSON_VALUE=$1; return 0 ;;
  esac
  # When every escape is one printf %b decodes the same way, printf does the work:
  # the whole value at once, or, with escaped quotes (which %b leaves alone), each
  # piece between them with its escaping backslash removed. A false alarm (an escaped
  # backslash before another letter) only takes the loop below.
  case $1 in
    *\\[!\\bfnrt\"]*) ;;
    *\"*)
      IFS='"' read -r -d '' -a segs <<< "$1" || true
      m=0
      for seg in "${segs[@]}"; do
        # Every piece but the last ends in the quote's backslash; the last ends in
        # the newline the here-string added.
        seg=${seg%\\}
        # bash 3.2 printf -v assigns its previous output when it prints nothing.
        if [ -n "$seg" ]; then
          printf -v h '%b' "$seg"
          o[m]=$h
        else
          o[m]=''
        fi
        m=$((m + 1))
      done
      printf -v JSON_VALUE '%s"' "${o[@]}"
      JSON_VALUE=${JSON_VALUE%\"}
      JSON_VALUE=${JSON_VALUE%$'\n'}
      return 0
      ;;
    *) printf -v JSON_VALUE '%b' "$1"; return 0 ;;
  esac
  # shellcheck disable=SC2141
  IFS=\\ read -r -d '' -a segs <<< "$1" || true
  o[0]=${segs[0]}
  # st is empty for an escape field, "l" for the text after an escaped backslash, or
  # the hex of a high surrogate waiting for its low half.
  for seg in "${segs[@]:1}"; do
    case $st in
      '') ;;
      l) o[m]=\\$seg; m=$((m + 1)); st=''; continue ;;
      *)
        case $seg in
          u[dD][c-fC-F][0-9a-fA-F][0-9a-fA-F]*)
            _json_utf8 $((65536 + ((16#$st - 55296) << 10) + (16#${seg:1:4} - 56320)))
            o[m]=$_JSON_BYTES${seg:5}
            m=$((m + 1))
            st=''
            continue
            ;;
        esac
        o[m]=\\u$st
        m=$((m + 1))
        st=''
        ;;
    esac
    case $seg in
      '') st=l; continue ;;
      '"'* | /*) o[m]=$seg ;;
      n*) o[m]=$'\n'${seg#?} ;;
      t*) o[m]=$'\t'${seg#?} ;;
      r*) o[m]=$'\r'${seg#?} ;;
      b*) o[m]=$'\b'${seg#?} ;;
      f*) o[m]=$'\f'${seg#?} ;;
      u[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]*)
        rest=${seg:5}
        code=$((16#${seg:1:4}))
        if [ "$code" -lt 128 ]; then
          if [ "$code" -gt 0 ]; then
            printf -v h '%02x' "$code"
            # shellcheck disable=SC2059
            printf -v _JSON_BYTES "\\x$h"
            o[m]=$_JSON_BYTES$rest
          else
            o[m]=$rest
          fi
        elif [ "$code" -lt 55296 ] || [ "$code" -gt 57343 ]; then
          _json_utf8 "$code"
          o[m]=$_JSON_BYTES$rest
        elif [ "$code" -le 56319 ] && [ -z "$rest" ]; then
          st=${seg:1:4}
          continue
        else
          o[m]=\\$seg
        fi
        ;;
      *) o[m]=\\$seg ;;
    esac
    m=$((m + 1))
  done
  # One printf joins the pieces; appending to a string piece by piece would copy it
  # every time, and "${o[*]}" with an empty IFS is not portable to bash 3.2. The
  # here-string added one newline at the very end, so no escape is left pending.
  printf -v JSON_VALUE '%s' "${o[@]}"
  JSON_VALUE=${JSON_VALUE%$'\n'}
}

# json_extract_string KEY JSON: set JSON_VALUE to the first string value under
# KEY, at any depth, in document order. Returns 1 when there is none.
json_extract_string() {
  # Byte semantics: in a multibyte locale every substring or length costs O(position).
  local LC_ALL=C
  JSON_VALUE=
  _json_seek "$1" "$2" string || return 1
  _json_decode "$_JSON_RAW"
  _JSON_RAW=
}

# json_extract_strings JSON KEY...: what json_extract_string finds for each KEY, from
# one split of JSON: JSON_VALUES[i] holds the value for the i-th KEY, unset when there
# is none. The walk stops once every KEY is found, so keys near the start of a large
# document (hook input fields) cost one linear split and a few steps.
json_extract_strings() {
  local LC_ALL=C p v prev='' st=0 i=0 n start=0 k j want=0 left
  local -a P=() keys=()
  JSON_VALUES=()
  keys=("${@:2}")
  left=${#keys[@]}
  [ "$left" -gt 0 ] || return 0
  IFS='"' read -r -d '' -a P <<< "$1" || true
  n=${#P[@]}
  for p in "${P[@]}"; do
    i=$((i + 1))
    case $st in
      2)
        # Inside the value: it ends at the first part not followed by an escaped quote.
        case $p in
          *[!\\]\\ | \\) continue ;;
          *\\) ! _json_odd_tail "$p" || continue ;;
        esac
        # The here-string added a newline, so the last part is never followed by a quote.
        [ "$i" -lt "$n" ] || break
        _json_join "$start" $((i - start))
        _json_decode "$_JSON_RAW"
        _JSON_RAW=
        JSON_VALUES[want]=$JSON_VALUE
        left=$((left - 1))
        [ "$left" -gt 0 ] || break
        st=0
        prev=$p
        continue
        ;;
      1)
        # The text between a key's closing quote and the next quote.
        st=0
        v=$p
        case $v in [[:space:]]*) v=${v#"${v%%[![:space:]]*}"} ;; esac
        case $v in
          :*)
            v=${v#:}
            case $v in [[:space:]]*) v=${v#"${v%%[![:space:]]*}"} ;; esac
            if [ -z "$v" ]; then
              st=2
              start=$i
              continue
            fi
            ;;
        esac
        ;;
    esac
    # A part is a key candidate when the quote before it is not escaped.
    if [ "$i" -gt 1 ] && ! { case $prev in *\\) _json_odd_tail "$prev" ;; *) false ;; esac; }; then
      j=0
      for k in "${keys[@]}"; do
        if [ "$p" = "$k" ] && [ -z "${JSON_VALUES[j]+x}" ]; then
          st=1
          want=$j
          break
        fi
        j=$((j + 1))
      done
    fi
    prev=$p
  done
  JSON_VALUE=
  return 0
}

# json_get_string KEY [JSON]: print the value; JSON defaults to stdin.
json_get_string() {
  local json
  if [ "$#" -ge 2 ]; then
    json=$2
  else
    IFS= read -r -d '' json || true
  fi
  json_extract_string "$1" "$json" || return 1
  printf '%s' "$JSON_VALUE"
}

# json_get_bool KEY [JSON]: print true or false for the first KEY whose value is
# a boolean literal. Exit 0 only for true; 1 for false or when absent.
json_get_bool() {
  local LC_ALL=C json
  if [ "$#" -ge 2 ]; then
    json=$2
  else
    IFS= read -r -d '' json || true
  fi
  _json_seek "$1" "$json" bool || return 1
  printf '%s' "$_JSON_BOOL"
  [ "$_JSON_BOOL" = true ]
}

# _json_sub CHAR REPL: replace every CHAR in the caller's s with REPL, linearly. Read
# treats control characters such as tab, newline and CR as IFS whitespace (runs would
# collapse), so those are read one field at a time with CHAR as the delimiter.
_json_sub() {
  local fmt=${2//\\/\\\\} part n=0
  local -a parts=()
  case $1 in
    [[:cntrl:]])
      while IFS= read -r -d "$1" part; do
        parts[n]=$part
        n=$((n + 1))
      done <<< "$s"
      parts[n]=$part
      ;;
    *) IFS=$1 read -r -d '' -a parts <<< "$s" || true ;;
  esac
  # shellcheck disable=SC2059
  printf -v s "%s$fmt" "${parts[@]}"
  # The here-string added a newline: a field of its own when CHAR is a newline,
  # otherwise the end of the last field.
  s=${s%"$2"}
  case $1 in
    $'\n') s=${s%"$2"} ;;
    *) s=${s%$'\n'} ;;
  esac
}

# json_escape STRING: print STRING as the body of a JSON string. Every C0 control
# character is escaped, so the output is always valid inside a JSON document.
# Bash 3.2 pattern substitution costs O(length) per match, so it is used only on
# short strings; longer ones are split and joined in linear time.
json_escape() {
  local LC_ALL=C s=$1 i h c short=
  [ "${#s}" -gt 512 ] || short=1
  if [ -n "$short" ]; then
    s=${s//\\/\\\\}
    s=${s//\"/\\\"}
  else
    case $s in *\\*) _json_sub "\\" "\\\\" ;; esac
    case $s in *\"*) _json_sub '"' '\"' ;; esac
  fi
  case $s in
    *[[:cntrl:]]*)
      for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31; do
        printf -v h '%02x' "$i"
        # shellcheck disable=SC2059
        printf -v c "\\x$h"
        case $s in *"$c"*) ;; *) continue ;; esac
        if [ -n "$short" ]; then
          case $i in
            9) s=${s//"$c"/\\t} ;;
            10) s=${s//"$c"/\\n} ;;
            13) s=${s//"$c"/\\r} ;;
            *) s=${s//"$c"/\\u00$h} ;;
          esac
        else
          case $i in
            9) _json_sub "$c" '\t' ;;
            10) _json_sub "$c" '\n' ;;
            13) _json_sub "$c" '\r' ;;
            *) _json_sub "$c" "\\u00$h" ;;
          esac
        fi
      done
      ;;
  esac
  printf '%s' "$s"
}
