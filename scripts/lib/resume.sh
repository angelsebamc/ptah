# The `resume` subcommand: prints a spec's last LOGS.md entry as one line,
# read through logs.sh. Uses specs.sh and logs.sh.

# Each line is <HH:MM> <type> — <what>. A change entry shows its Type: and
# What:. A command entry shows /<command> <status> and the field resuming
# depends on: Next step: when completed, Blocked on: when paused, Reason: when failed.
cmd_resume() {
  (( $# == 1 )) || die "usage: ptah resume <spec-id>"
  local folder n entries
  folder=$(resolve "$1")
  n=$(spec_number "$folder")
  entries=$(read_entries "$folder")
  if [[ -z $entries ]]; then
    printf 'Spec %s was started but its SPEC.md was never written. Next step: `/ptah:spec %s` to continue it.\n' "$n" "$n"
    return
  fi
  printf '%s\n' "$entries" | awk -F'\t' '
    $1 == "entry" {
      when = substr($3, 12, 5); what = ""
      if ($2 == "change") { type = ""; key = "What" }
      else {
        type = "/" $4 " " $5
        key = ($5 == "paused") ? "Blocked on" : ($5 == "failed") ? "Reason" : "Next step"
      }
      next
    }
    $2 == "Type" && type == "" { type = $3 }
    $2 == key { what = $3 }
    END { print "Last entry: " when " " type " — " what }
  '
}
