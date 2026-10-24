# Reads the guides: fixed values from vocabulary.md, entry fields from the
# tables in logs-format.md. The only file that knows how those guides are laid out.

# vocab <section> → the section's values from vocabulary.md, one per line
vocab() {
  awk -v s="$1" '
    { sub(/\r$/, "") }
    /^## / { on = (tolower(substr($0, 4)) == tolower(s)); next }
    on && /^\| *`/ { split($0, c, "|"); v = c[2]; gsub(/^[ \t]*`|`[ \t]*$/, "", v); print v }
  ' "$VOCAB"
}

# logged_as <result-status> → the command status it maps to, or nothing
logged_as() {
  awk -v v="$1" '
    { sub(/\r$/, "") }
    /^## / { on = (substr($0, 4) == "Result status"); next }
    on && /^\| *`/ {
      split($0, c, "|"); k = c[2]; l = c[4]
      gsub(/^[ \t]*`|`[ \t]*$/, "", k); gsub(/^[ \t]*`|`[ \t]*$/, "", l)
      if (k == v) print l
    }
  ' "$VOCAB"
}

# field_specs <heading> → "Field<TAB>Value" rows of the table under ### `<heading>`
field_specs() {
  awk -v h="### \`$1\`" '
    { sub(/\r$/, "") }
    $0 == h { on = 1; next }
    on && /^#/ { exit }
    on && /^\|/ {
      split($0, c, "|"); f = c[2]; s = c[3]
      gsub(/^[ \t]+|[ \t]+$/, "", f); gsub(/^[ \t]+|[ \t]+$/, "", s)
      if (f == "Field" || f ~ /^:?-+:?$/) next
      print f "\t" s
    }
  ' "$LOGFMT"
}

# entry_specs <command> <status> → field rows for a command entry
entry_specs() {
  local rows
  rows=$(field_specs "/$1 $2")
  [[ -n $rows ]] || rows=$(field_specs "/<command> $2")
  [[ -n $rows ]] || die "logs-format.md defines no fields for /$1 $2."
  printf '%s\n' "$rows"
}

# check_fields <specs-file> <fields-file> → prints the first problem, if any.
# Exits 2 when logs-format.md itself uses a value shape it doesn't define.
check_fields() {
  awk -F'\t' -v vocab="$VOCAB" '
    function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
    function load_vocab(   line, sec, c, v) {
      while ((getline line < vocab) > 0) {
        sub(/\r$/, "", line)
        if (line ~ /^## /) { sec = tolower(substr(line, 4)); known[sec] = 1; continue }
        if (sec != "" && line ~ /^\| *`/) {
          split(line, c, "|"); v = c[2]; gsub(/^[ \t]*`|`[ \t]*$/, "", v); allowed[sec, v] = 1
        }
      }
      close(vocab)
    }
    # A literal value, with <count> standing for digits and any other <...> for text.
    function literal_re(lit,   out, i, ch, j, name) {
      out = "^"
      for (i = 1; i <= length(lit); i++) {
        ch = substr(lit, i, 1)
        if (ch == "<" && (j = index(substr(lit, i), ">")) > 0) {
          name = substr(lit, i + 1, j - 2)
          out = out (name == "count" ? "[0-9]+" : ".+")
          i += j - 1
        } else if (index("\\^$.[]|()*+?{}/", ch)) out = out "\\" ch
        else out = out ch
      }
      return out "$"
    }
    function keyword_ok(v, kw) {
      kw = tolower(kw)
      if (kw == "text") return 1
      if (kw == "count") return v ~ /^[0-9]+$/
      if (kw in known) return ((kw, v) in allowed)
      printf "logs-format.md uses an unknown value shape: %s\n", kw > "/dev/stderr"
      bad = 1
      exit 2
    }
    function shape_ok(v, shape,   rest, j, alt) {
      rest = shape
      while (rest != "") {
        if (substr(rest, 1, 1) == "`") {
          j = index(substr(rest, 2), "`")
          alt = substr(rest, 2, j - 1); rest = substr(rest, j + 2)
          if (v ~ literal_re(alt)) return 1
        } else {
          if (match(rest, /,|[ \t]or[ \t]/)) { alt = substr(rest, 1, RSTART - 1); rest = substr(rest, RSTART) }
          else { alt = rest; rest = "" }
          if (keyword_ok(v, trim(alt))) return 1
        }
        sub(/^[ \t]*,?[ \t]*(or[ \t]+)?/, "", rest)
      }
      return 0
    }
    BEGIN { load_vocab() }
    NR == FNR { name[++n] = $1; shape[n] = $2; next }
    {
      sub(/\r$/, "")
      if (++m > n) { problem = "unexpected field: " $0; exit }
      i = index($0, ": ")
      if (!i) { problem = "expected \"" name[m] ": <value>\", got \"" $0 "\""; exit }
      f = substr($0, 1, i - 1); v = substr($0, i + 2)
      if (f != name[m]) { problem = "expected field " name[m] ", got " f; exit }
      if (v == "" || v != trim(v)) { problem = f " is empty or has surrounding whitespace"; exit }
      if (!shape_ok(v, shape[m])) { problem = "invalid " f ": " v " (expected " shape[m] ")"; exit }
    }
    END {
      if (bad) exit 2
      if (problem == "" && m < n) problem = "missing field " name[m + 1]
      if (problem != "") print problem
    }
  ' "$1" "$2"
}
