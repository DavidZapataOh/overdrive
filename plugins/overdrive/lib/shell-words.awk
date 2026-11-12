# Shell command reader for the PreToolUse guard. Input: one shell command (any number
# of lines); environment: OD_CWD (absolute starting directory) and HOME. Prints one
# record per relevant part, fields split by \037:
#   D DIR                a command runs in DIR (printed when DIR changes)
#   W DIR WORD           WORD is written or removed (a directory covers its files)
#   C DIR DEST SRC       SRC is copied to DEST (DEST itself, or DEST/basename SRC)
#   P DIR ARG...         git push run in DIR, with its arguments
#   S DIR switch         git switch, or a git checkout that creates, detaches or goes back (-)
#   S DIR OP...          git checkout without --: a switch unless every OP is a path
#   K DIR FLAGS mMSG fFILE PATH...  git commit: see commit() below
# Quotes, escapes, comments, line continuations, here-documents (bodies skipped),
# subshells, cd, pushd/popd, git -C, common wrappers (sudo, env, nice, timeout...) and
# the strings of sh -c and eval are followed; variables, globs and command
# substitution output are left as written. POSIX awk: split(s, a, "") into characters
# works in every awk in use.

function out(kind, d, a, b) {
  gsub(/\n/, "?", a); gsub(/\n/, "?", b)
  print kind US d US a (b == "" ? "" : US b)
}
function rec(kind, d, from,   k, r) {
  r = kind US d
  for (k = from; k <= nw; k++) { gsub(/\n/, "?", w[k]); r = r US w[k] }
  print r
}
function ran(d) {
  if (d != lastd) { print "D" US d; lastd = d }
}
function resolve(base, p) {
  if (p ~ /^\// || p ~ /^[A-Za-z]:/) return p
  if (p == "~") return home
  if (substr(p, 1, 2) == "~/") return home substr(p, 2)
  return base "/" p
}
function endword() {
  if (word == "" && !has) return
  if (redir == "out" || (redir == "dup" && word !~ /^([0-9]+-?|-)$/)) {
    if (word !~ /^\/dev\//) out("W", dir, word)
  } else if (redir == "hd" || redir == "hdstrip") {
    hd[++nhd] = word; hdstrip[nhd] = (redir == "hdstrip")
  } else if (redir == "") w[++nw] = word
  redir = ""; word = ""; has = 0
}
function operands(d, j, kind,   dd) {
  for (; j <= nw; j++) {
    if (!dd && w[j] == "--") { dd = 1; continue }
    if (w[j] == "" || (!dd && w[j] ~ /^-/)) continue
    out(kind, d, w[j])
  }
}
function copyish(d, j, move,   k, n, ops, t, dd) {
  n = 0; t = ""
  for (; j <= nw; j++) {
    if (!dd && w[j] == "--") { dd = 1; continue }
    if (!dd && (w[j] == "-t" || w[j] == "--target-directory")) { t = w[++j]; continue }
    if (!dd && w[j] ~ /^--target-directory=/) { t = substr(w[j], 20); continue }
    if (!dd && w[j] ~ /^-t./) { t = substr(w[j], 3); continue }
    if (w[j] == "" || (!dd && w[j] ~ /^-/)) continue
    ops[++n] = w[j]
  }
  if (t == "") { if (n == 1) t = "."; else t = ops[n--] }
  for (k = 1; k <= n; k++) {
    out("C", d, t, ops[k])
    if (move) out("W", d, ops[k])
  }
}
# inplace J PERL: true when the options from word J edit files in place. Each short
# option cluster is read letter by letter: letters that take an argument end the
# cluster (sed -e -f -l; perl -e -E -M -m -I -x), and take the next word when they
# end the word too; perl -0 and -l take the octal digits that follow.
function inplace(j, perl,   k, o, c, n) {
  for (; j <= nw; j++) {
    o = w[j]
    if (o == "--") return 0
    if (o ~ /^--in-place/) return 1
    if (o ~ /^--/ || o !~ /^-./) continue
    n = length(o)
    for (k = 2; k <= n; k++) {
      c = substr(o, k, 1)
      if (c == "i") return 1
      if (perl && (c == "M" || c == "m" || c == "I" || c == "x")) break
      if (c == "e" || (perl ? c == "E" : (c == "f" || c == "l"))) { if (k == n) j++; break }
      if (perl && (c == "0" || c == "l")) { while (k < n && substr(o, k + 1, 1) ~ /[0-9a-fA-Fx]/) k++ }
    }
  }
  return 0
}
# sortout D J: sort -o FILE, -oFILE, -no FILE, --output[=]FILE writes FILE.
function sortout(d, j,   k, o, c, n) {
  for (; j <= nw; j++) {
    o = w[j]
    if (o == "--") return
    if (o ~ /^--output=/) { out("W", d, substr(o, 10)); continue }
    if (o == "--output") { out("W", d, w[++j]); continue }
    if (o ~ /^--/ || o !~ /^-./) continue
    n = length(o)
    for (k = 2; k <= n; k++) {
      c = substr(o, k, 1)
      if (c == "o") { if (k == n) out("W", d, w[++j]); else out("W", d, substr(o, k + 1)); break }
      if (c ~ /[ktST]/) { if (k == n) j++; break }
    }
  }
}
# awkinplace D J: gawk -i inplace (or --include=inplace) rewrites every input file:
# the words after the program, skipping option arguments and var=value assignments.
function awkinplace(d, j,   k, o, ip, prog) {
  for (k = j; k <= nw; k++) {
    o = w[k]
    if (o == "-i" || o == "--include") { if (w[k + 1] ~ /^inplace(\.awk)?$/) ip = 1; k++ }
    else if (o ~ /^(-i|--include=)inplace(\.awk)?$/) ip = 1
  }
  if (!ip) return
  prog = 1
  for (; j <= nw; j++) {
    o = w[j]
    if (o == "--") continue
    if (o ~ /^-[fvFiel]$/ || o == "--include" || o == "--file" || o == "--assign") { if (o == "-f" || o == "--file") prog = 0; j++; continue }
    if (o ~ /^-/) { if (o ~ /^(-f|--file=)/) prog = 0; continue }
    if (prog) { prog = 0; continue }
    if (o ~ /^[A-Za-z_][A-Za-z0-9_]*=/) continue
    out("W", d, o)
  }
}
# uniqout D J: uniq IN OUT writes OUT.
function uniqout(d, j,   n, o, ops) {
  n = 0
  for (; j <= nw; j++) {
    o = w[j]
    if (o ~ /^-[fsw]$/) { j++; continue }
    if (o ~ /^-./) continue
    ops[++n] = o
  }
  if (n >= 2) out("W", d, ops[2])
}
# commit D J: git commit with its words from J. FLAGS: a (-a/--all), n (--dry-run), s
# (the index may not be what the commit records: another command ran before it in this
# command line, or -p, --interactive, --include or --pathspec-from-file selects content).
# Then the message text from -m/--message ("m" + text), the -F/--file path ("f" + path)
# and the pathspec operands. Options that take a value consume the next word.
function commit(d, j,   k, o, c, n, flags, ops, dd, msg, mfile, v) {
  flags = nprior > 0 ? "s" : ""
  for (k = j; k <= nw; k++) {
    o = w[k]
    if (dd || o !~ /^-./) { if (o == "--") { dd = 1; continue }; ops = ops US o; continue }
    if (o ~ /^--/) {
      if (o == "--all") flags = flags "a"
      else if (o == "--dry-run") flags = flags "n"
      else if (o == "--patch" || o == "--interactive" || o == "--include" || o ~ /^--pathspec-from-file/) flags = flags "s"
      else if (o == "--message" || o ~ /^--message=/) { v = o == "--message" ? w[++k] : substr(o, 11); msg = msg (msg == "" ? "" : " ") v }
      else if (o == "--file" || o ~ /^--file=/) mfile = o == "--file" ? w[++k] : substr(o, 8)
      else if (o ~ /^--(author|date|reuse-message|reedit-message|fixup|squash|template|cleanup|trailer)$/) k++
      continue
    }
    n = length(o)
    for (c = 2; c <= n; c++) {
      v = substr(o, c, 1)
      if (v == "a") flags = flags "a"
      else if (v == "p" || v == "i") flags = flags "s"
      else if (v == "m") { msg = msg (msg == "" ? "" : " ") (c < n ? substr(o, c + 1) : w[++k]); break }
      else if (v == "F") { mfile = c < n ? substr(o, c + 1) : w[++k]; break }
      else if (v ~ /[Cct]/) { if (c == n) k++; break }
      else if (v ~ /[uS]/) break
    }
  }
  gsub(/\n/, " ", msg)
  print "K" US d US (flags == "" ? "-" : flags) US "m" msg US "f" mfile ops
}
function git(d, j,   g, k, dd, sw, any) {
  g = d
  while (j <= nw && w[j] ~ /^-/) {
    if (w[j] == "-C") { g = resolve(g, w[j + 1]); j += 2 }
    else if (w[j] == "-c" || w[j] == "--git-dir" || w[j] == "--work-tree" || w[j] == "--namespace") j += 2
    else j++
  }
  ran(g)
  if (j > nw) return
  if (w[j] == "push") rec("P", g, j + 1)
  else if (w[j] == "commit") commit(g, j + 1)
  else if (w[j] == "switch") out("S", g, "switch")
  else if (w[j] == "restore" || w[j] == "rm" || w[j] == "mv") operands(g, j + 1, "W")
  else if (w[j] == "checkout") {
    operands(g, j + 1, "W")
    for (k = j + 1; k <= nw; k++) {
      if (w[k] == "--") dd = 1
      else if (w[k] ~ /^(-[bBd]|-|--orphan|--detach)$/) sw = 1
      else if (w[k] !~ /^-/) any = 1
    }
    if (sw) out("S", g, "switch")
    else if (!dd && any) rec("S", g, j + 1)
  }
}
# shell I: queue the string that sh -c, bash -lc ... runs, from the words after I.
function shell(i,   k, o) {
  for (k = i; k <= nw; k++) {
    o = w[k]
    if (o !~ /^-/) return
    if (o ~ /^-[A-Za-z]*c[A-Za-z]*$/ && k < nw) { queue(w[k + 1]); return }
  }
}
function queue(s) {
  if (nq < 32) { qs[++nq] = s; qd[nq] = dir }
}
function endseg(   i, c, j, d, t) {
  endword(); redir = ""
  d = dir
  i = 1
  while (i <= nw) {
    c = w[i]
    if (c ~ /^[A-Za-z_][A-Za-z0-9_]*=/ || c == "!" || c == "{" || c == "then" || c == "do" || c == "else" || c == "if" || c == "while" || c == "until") { i++; continue }
    t = c; sub(/.*\//, "", t)
    if (t in wrapper) {
      i++
      while (i <= nw && w[i] ~ /^-./ && w[i] != "--") {
        if ((t == "env" && w[i] == "-C") || (t == "sudo" && w[i] == "-D")) { d = resolve(d, w[i + 1]); i += 2 }
        else if (index(wrapper[t], " " w[i] " ")) i += 2
        else i++
      }
      if (i <= nw && w[i] == "--") i++
      if (t == "timeout" && i <= nw) i++
      continue
    }
    break
  }
  if (i <= nw) {
    c = w[i]; sub(/.*\//, "", c)
    if (c == "cd") { if (i < nw && w[i + 1] != "-") dir = resolve(dir, w[i + 1]); else if (i == nw) dir = home }
    else if (c == "pushd") { if (i < nw) { ps[++np] = dir; dir = resolve(dir, w[i + 1]) } }
    else if (c == "popd") { if (np > 0) dir = ps[np--] }
    else if (c == "git") git(d, i + 1)
    else {
      ran(d)
      if (c == "rm" || c == "unlink" || c == "shred" || c == "tee" || c == "truncate") operands(d, i + 1, "W")
      else if (c == "mv") copyish(d, i + 1, 1)
      else if (c == "cp" || c == "ln" || c == "install") copyish(d, i + 1, 0)
      else if ((c == "sed" || c == "perl") && inplace(i + 1, c == "perl")) operands(d, i + 1, "W")
      else if (c == "sort") sortout(d, i + 1)
      else if (c == "awk" || c == "gawk") awkinplace(d, i + 1)
      else if (c == "uniq") uniqout(d, i + 1)
      else if (c == "dd") { for (j = i + 1; j <= nw; j++) if (w[j] ~ /^of=/) out("W", d, substr(w[j], 4)) }
      else if (c == "sh" || c == "bash" || c == "zsh" || c == "dash" || c == "ksh") shell(i + 1)
      else if (c == "eval" && i < nw) {
        t = w[i + 1]
        for (j = i + 2; j <= nw; j++) t = t " " w[j]
        queue(t)
      }
    }
  }
  if (i <= nw && c != "cd" && c != "pushd" && c != "popd") nprior++
  nw = 0
}
# feed LINE: read one line of the command; here-document bodies are skipped.
function feed(line,   n, ch, i, c, cont) {
  if (skip) {
    if (hdstrip[hdi]) sub(/^\t+/, "", line)
    if (line == hd[hdi] && ++hdi > nhd) { skip = 0; nhd = 0 }
    return
  }
  n = split(line, ch, "")
  for (i = 1; i <= n; i++) {
    c = ch[i]
    if (insq) { if (c == sq) insq = 0; else word = word c; continue }
    if (indq) {
      if (c == bs && i == n) { cont = 1; continue }
      if (c == bs && (ch[i + 1] == "$" || ch[i + 1] == "`" || ch[i + 1] == dq || ch[i + 1] == bs)) { word = word ch[++i]; continue }
      if (c == dq) indq = 0; else word = word c
      continue
    }
    if (c == bs) { if (i == n) { cont = 1; continue } word = word ch[++i]; has = 1; continue }
    if (c == sq) { insq = 1; has = 1; continue }
    if (c == dq) { indq = 1; has = 1; continue }
    if (c == " " || c == "\t") { endword(); continue }
    if (c == "#" && word == "" && !has) break
    if (c == ">" || c == "<") {
      if (word ~ /^[0-9]+$/) { word = ""; has = 0 } else endword()
      if (c == ">") {
        if (ch[i + 1] == ">" || ch[i + 1] == "|") i++
        if (ch[i + 1] == "&") { i++; redir = "dup" } else redir = "out"
      } else if (ch[i + 1] == "<") {
        i++
        if (ch[i + 1] == "<") { i++; redir = "in" }
        else if (ch[i + 1] == "-") { i++; redir = "hdstrip" }
        else redir = "hd"
      } else if (ch[i + 1] == ">") { i++; redir = "out" }
      else { if (ch[i + 1] == "&") i++; redir = "in" }
      continue
    }
    if (c == "&" && ch[i + 1] == ">") { endword(); i++; if (ch[i + 1] == ">") i++; redir = "out"; continue }
    # A subshell or command substitution keeps its own directory.
    if ((c == "$" && ch[i + 1] == "(") || c == "(") { endseg(); if (c == "$") i++; st[++sp] = dir; continue }
    if (c == ")") { endseg(); if (sp > 0) dir = st[sp--]; continue }
    if (c == "`" || c == ";" || c == "&" || c == "|") { endseg(); continue }
    word = word c; has = 1
  }
  if (insq || indq) { word = word "\n"; return }
  if (cont) return
  endseg()
  if (nhd > 0) { skip = 1; hdi = 1 }
}
function reset() {
  word = ""; has = 0; insq = 0; indq = 0; redir = ""; nw = 0; nhd = 0; skip = 0; sp = 0; np = 0
}
BEGIN {
  US = "\037"; dir = ENVIRON["OD_CWD"]; home = ENVIRON["HOME"]; sq = "\047"; dq = "\""; bs = "\\"
  # Wrappers that run the command after their options; each lists its options that
  # take a separate argument.
  wrapper["sudo"] = " -u -g -C -D -h -p -U -r -t -T "
  wrapper["env"] = " -u -S -C "
  wrapper["nice"] = " -n "
  wrapper["timeout"] = " -s -k "
  wrapper["stdbuf"] = " -i -o -e "
  wrapper["nohup"] = " "
  wrapper["command"] = " "
  wrapper["builtin"] = " "
  wrapper["exec"] = " -a "
  wrapper["time"] = " -o -f "
  wrapper["xargs"] = " -I -n -P -L -d -s -a -E "
  wrapper["ionice"] = " -c -n -p "
}
{ feed($0) }
END {
  endseg()
  # Strings run by sh -c and eval, each read from the directory it was given in.
  for (q = 1; q <= nq; q++) {
    reset()
    dir = qd[q]
    n = split(qs[q], lines, "\n")
    for (k = 1; k <= n; k++) feed(lines[k])
    endseg()
  }
}
