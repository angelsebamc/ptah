# Spec folders: resolving a spec id, and creating the next numbered spec
# from specs.next_id in ptah.yml.

resolve() {
  (( $# == 1 )) || die "usage: ptah resolve <spec-id>"
  local id=$1 n d count=0 match=
  if [[ $id != .* && $id != */* && -d $SPECS/$id ]]; then printf '%s\n' "$id"; return; fi
  n=${id#ptah-}
  n=${n%%[!0-9]*}
  if [[ -n $n ]]; then
    for d in "$SPECS"/ptah-"$n"-*; do
      [[ -d $d ]] || continue
      count=$((count + 1)); match=${d##*/}
    done
  fi
  (( count == 1 )) || die "No spec found for \`$id\`."
  printf '%s\n' "$match"
}

spec_number() { local n=${1#ptah-}; printf '%s\n' "${n%%-*}"; }

# Prints specs.next_id from ptah.yml, or nothing when it isn't set.
read_next_id() {
  [[ -f $CONFIG ]] || return 0
  local v
  v=$(awk -v sq="'" '
    { sub(/\r$/, "") }
    /^[^ \t#]/ {
      if ($0 ~ /^specs:[ \t]*[^ \t#]/) { print "!flow"; exit }
      insec = ($0 ~ /^specs:[ \t]*(#.*)?$/); next
    }
    insec && /^[ \t]+next_id:/ {
      v = $0; sub(/^[ \t]+next_id:[ \t]*/, "", v); sub(/[ \t]*(#.*)?$/, "", v)
      gsub("^[\"" sq "]|[\"" sq "]$", "", v); print v; exit
    }
  ' "$CONFIG")
  [[ $v != '!flow' ]] || die "Can't edit the specs section of $CONFIG. Write it as a block (specs: then next_id: on its own line) and re-run."
  [[ -z $v || $v =~ ^[0-9]+$ ]] || die "specs.next_id in $CONFIG isn't a number: $v"
  printf '%s' "$v"
}

# write_next_id <value> <had-next-id: 0|1> — changes only specs.next_id
write_next_id() {
  if [[ ! -f $CONFIG ]]; then
    mkdir -p "${CONFIG%/*}"
    printf 'specs:\n  next_id: %s\n' "$1" > "$CONFIG"
    return
  fi
  awk -v n="$1" -v has="$2" '
    { eol = sub(/\r$/, "") ? "\r" : "" }
    /^[^ \t#]/ {
      insec = ($0 ~ /^specs:[ \t]*(#.*)?$/)
      if (insec && !has) { print $0 eol; print "  next_id: " n eol; done = 1; next }
    }
    insec && has && !done && /^[ \t]+next_id:/ {
      match($0, /^[ \t]+next_id:[ \t]*/); pre = substr($0, 1, RLENGTH); rest = substr($0, RLENGTH + 1)
      comment = match(rest, /[ \t]+#.*$/) ? substr(rest, RSTART) : ""
      print pre n comment eol; done = 1; next
    }
    { print $0 eol }
    END { if (!done) { print "specs:" eol; print "  next_id: " n eol } }
  ' "$CONFIG" > "$CONFIG.tmp"
  mv "$CONFIG.tmp" "$CONFIG"
}

cmd_new_spec() {
  (( $# >= 1 )) || die "usage: ptah new-spec <feature-name>"
  local name="$*" slug n has=1 d folder f
  slug=$(printf '%s' "$name" | tr '[:upper:]' '[:lower:]' \
    | sed -e 's/[ _]/-/g' -e 's/[^a-z0-9-]//g' -e 's/--*/-/g' -e 's/^-//' -e 's/-$//')
  [[ -n $slug ]] || die "Can't build a slug from \"$name\"."
  n=$(read_next_id)
  if [[ -z $n ]]; then n=1; has=0; fi
  for d in "$SPECS"/ptah-"$n"-*; do
    if [[ -e $d ]]; then
      die "specs.next_id is $n, but $d already exists. Set specs.next_id in $CONFIG past the highest spec number and re-run."
    fi
  done
  # Bump the counter first: a number may be skipped, never reused.
  write_next_id $((n + 1)) "$has"
  folder="ptah-$n-$slug"
  mkdir -p "$SPECS/$folder/refs"
  for f in LOGS.md SPEC.md PLAN.md IMPLEMENTATION-SUMMARY.md REVIEW.md; do
    [[ -e $SPECS/$folder/$f ]] || : > "$SPECS/$folder/$f"
  done
  printf '%s %s\n' "$n" "$folder"
}
