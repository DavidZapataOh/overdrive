# Shell command reader for the PreToolUse guard. Input: one shell command (any number
# of lines); environment: OD_CWD (absolute starting directory) and HOME. Prints one
# record per relevant part, fields split by \037:
#   W DIR WORD           WORD is written or removed (a directory covers its files)
#   C DIR DEST SRC       SRC is copied to DEST (DEST itself, or DEST/basename SRC)
#   P DIR ARG...         git push run in DIR, with its arguments
# Quotes, escapes, comments, line continuations, here-documents (bodies skipped), cd
# and git -C are followed; variables, globs and command substitutions are left as
# written. POSIX awk: split(s, a, "") into characters works in every awk in use.

function out(kind, d, a, b) {
  gsub(/\n/, "?", a); gsub(/\n/, "?", b)
  print kind US d US a (b == "" ? "" : US b)
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
function copyish(j, move,   k, n, ops, t, dd) {
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
    out("C", dir, t, ops[k])
    if (move) out("W", dir, ops[k])
  }
}
function inplace(j, perl) {
  for (; j <= nw; j++) {
    if (w[j] == "--") return 0
    if (w[j] ~ /^--in-place/ || (w[j] ~ /^-[A-Za-z0-9]*i/ && w[j] !~ /^--/)) return 1
    if (!perl && (w[j] == "-e" || w[j] == "-f")) j++
  }
  return 0
}
function git(j,   g, k, rec) {
  g = dir
  while (j <= nw && w[j] ~ /^-/) {
    if (w[j] == "-C") { g = resolve(g, w[j + 1]); j += 2 }
    else if (w[j] == "-c" || w[j] == "--git-dir" || w[j] == "--work-tree" || w[j] == "--namespace") j += 2
    else j++
  }
  if (j > nw) return
  if (w[j] == "push") {
    rec = ""
    for (k = j + 1; k <= nw; k++) { gsub(/\n/, "?", w[k]); rec = rec US w[k] }
    print "P" US g rec
  } else if (w[j] == "checkout" || w[j] == "restore" || w[j] == "rm" || w[j] == "mv") operands(g, j + 1, "W")
}
function endseg(   i, c, j) {
  endword(); redir = ""
  i = 1
  while (i <= nw) {
    c = w[i]
    if (c ~ /^[A-Za-z_][A-Za-z0-9_]*=/ || c == "!" || c == "{" || c == "then" || c == "do" || c == "else" || c == "if" || c == "while" || c == "until" || c == "time") { i++; continue }
    if (c == "sudo" || c == "env" || c == "nohup" || c == "command" || c == "builtin" || c == "exec" || c == "xargs") {
      i++
      while (i <= nw && w[i] ~ /^-/) i++
      continue
    }
    break
  }
  if (i <= nw) {
    c = w[i]; sub(/.*\//, "", c)
    if (c == "cd") { if (i < nw && w[i + 1] != "-") dir = resolve(dir, w[i + 1]); else if (i == nw) dir = home }
    else if (c == "git") git(i + 1)
    else if (c == "rm" || c == "unlink" || c == "shred" || c == "tee" || c == "truncate") operands(dir, i + 1, "W")
    else if (c == "mv") copyish(i + 1, 1)
    else if (c == "cp" || c == "ln" || c == "install") copyish(i + 1, 0)
    else if ((c == "sed" || c == "perl") && inplace(i + 1, c == "perl")) operands(dir, i + 1, "W")
    else if (c == "dd") { for (j = i + 1; j <= nw; j++) if (w[j] ~ /^of=/) out("W", dir, substr(w[j], 4)) }
  }
  nw = 0
}
BEGIN { US = "\037"; dir = ENVIRON["OD_CWD"]; home = ENVIRON["HOME"]; sq = "\047"; dq = "\""; bs = "\\" }
skip {
  line = $0
  if (hdstrip[hdi]) sub(/^\t+/, "", line)
  if (line == hd[hdi] && ++hdi > nhd) { skip = 0; nhd = 0 }
  next
}
{
  n = split($0, ch, "")
  cont = 0
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
    if (c == "$" && ch[i + 1] == "(") { endseg(); i++; continue }
    if (c == "`" || c == ";" || c == "&" || c == "|" || c == "(" || c == ")") { endseg(); continue }
    word = word c; has = 1
  }
  if (insq || indq) { word = word "\n"; next }
  if (cont) next
  endseg()
  if (nhd > 0) { skip = 1; hdi = 1 }
}
END { endseg() }
