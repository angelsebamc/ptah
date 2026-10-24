# LOGS.md: the only file that knows its layout. Appends entries, reads them
# back, and runs the `log` subcommand. Uses schema.sh and specs.sh.

# append_entry <folder> <heading after the timestamp> <fields-file>
append_entry() {
  local log="$SPECS/$1/LOGS.md" ts
  ts=$(date '+%Y-%m-%d %H:%M:%S')
  {
    if [[ -s $log ]]; then
      if [[ -n $(tail -c 1 "$log") ]]; then printf '\n\n'
      elif [[ -n $(tail -n 1 "$log" | tr -d '\r \t') ]]; then printf '\n'
      fi
    fi
    printf '## %s — %s\n' "$ts" "$2"
    awk '{ sub(/\r$/, ""); print "- " $0 }' "$3"
  } >> "$log"
  printf '## %s — %s\n' "$ts" "$2"
  awk '{ print "- " $0 }' "$3"
}

# read_entries <folder> → the spec's LOGS.md as tab-separated records, in order:
#   entry <TAB> command|change <TAB> <YYYY-MM-DD HH:MM:SS> <TAB> <command> <TAB> <status, empty for change> <TAB> <heading line>
#   field <TAB> <name> <TAB> <value> <TAB> <field line>
read_entries() {
  local log="$SPECS/$1/LOGS.md"
  [[ -f $log ]] || return 0
  awk '
    BEGIN { OFS = "\t" }
    { sub(/\r$/, "") }
    /^## / {
      i = index($0, " — "); ts = substr($0, 4, i - 4); rest = substr($0, i + length(" — "))
      if (rest ~ /^change during \//) { kind = "change"; cmd = substr(rest, length("change during /") + 1); status = "" }
      else { kind = "command"; cmd = substr(rest, 2); status = cmd; sub(/ .*$/, "", cmd); sub(/^[^ ]* /, "", status) }
      print "entry", kind, ts, cmd, status, $0
      next
    }
    /^- / {
      line = substr($0, 3); i = index(line, ": ")
      if (i) print "field", substr(line, 1, i - 1), substr(line, i + 2), $0
      else print "field", line, "", $0
    }
  ' "$log"
}

cmd_log() {
  local kind=${1:-} folder cmd heading problem a
  case $kind in
    command) (( $# >= 5 )) || die "usage: ptah log command <spec-id> <command> <status> '<Field>: <value>'..." ;;
    change)  (( $# >= 4 )) || die "usage: ptah log change <spec-id> <command> '<Field>: <value>'..." ;;
    *) usage ;;
  esac
  folder=$(resolve "$2")
  cmd=$3
  [[ $cmd =~ ^[a-z]+$ ]] || die "Not a command name: $cmd"
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' EXIT
  if [[ $kind == command ]]; then
    vocab "Command status" | grep -qxF -- "$4" || die "Not a command status: $4"
    heading="/$cmd $4"
    entry_specs "$cmd" "$4" > "$tmp/specs"
    shift 4
  else
    heading="change during /$cmd"
    field_specs "change during /<command>" > "$tmp/specs"
    [[ -s $tmp/specs ]] || die "logs-format.md defines no fields for change entries."
    shift 3
  fi
  : > "$tmp/fields"
  for a in "$@"; do
    [[ $a != *$'\n'* ]] || die "LOGS.md entry not written: a value spans lines: $a"
    printf '%s\n' "$a" >> "$tmp/fields"
  done
  problem=$(check_fields "$tmp/specs" "$tmp/fields")
  [[ -z $problem ]] || die "LOGS.md entry not written: $problem"
  append_entry "$folder" "$heading" "$tmp/fields"
}
