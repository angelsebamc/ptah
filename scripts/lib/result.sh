# Subagent results: the `apply-result` subcommand. Uses schema.sh, specs.sh and logs.sh.

cmd_apply_result() {
  (( $# == 2 )) || die "usage: ptah apply-result <command> <spec-id>"
  local cmd=$1 folder n expected result parsed problem= art= first rstatus logged= types q tag verdict next
  case $cmd in
    plan) expected=PLAN.md ;;
    implement) expected=IMPLEMENTATION-SUMMARY.md ;;
    review) expected=REVIEW.md ;;
    *) die "apply-result handles plan, implement and review, not $cmd." ;;
  esac
  folder=$(resolve "$2")
  n=$(spec_number "$folder")
  result="$SPECS/$folder/.result.md"
  [[ -s $result ]] || die "No result to apply: $result is missing or empty."
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' EXIT
  : > "$tmp/fields"; : > "$tmp/questions"; : > "$tmp/artifact"

  # Split the result into its blocks, checking the structural rules.
  parsed=$(awk -v dir="$tmp" '
    { sub(/\r$/, "") }
    state == "" {
      if ($0 == "") next
      if ($0 != "===RESULT===") { problem = "text before ===RESULT==="; exit }
      state = "fields"; next
    }
    state == "done" { if ($0 != "") { problem = "text after ===END==="; exit } next }
    $0 == "===END===" { state = "done"; next }
    /^===[^=]+===$/ {
      if (art != "") { problem = "more than one artifact block"; exit }
      art = substr($0, 4, length($0) - 6); state = "artifact"; next
    }
    state == "artifact" { print > (dir "/artifact"); next }
    state == "fields" && $0 == "### Questions" { state = "questions"; next }
    state == "fields" && /^- / { print substr($0, 3) > (dir "/fields"); next }
    state == "questions" && /^- / { print > (dir "/questions"); next }
    $0 == "" { next }
    { problem = "unexpected line: " $0; exit }
    END {
      if (problem == "" && state == "") problem = "no ===RESULT=== block"
      else if (problem == "" && state != "done") problem = "no ===END==="
      if (problem != "") print "!" problem; else print art
    }
  ' "$result")
  if [[ $parsed == !* ]]; then problem=${parsed#!}; else art=$parsed; fi

  if [[ -z $problem ]]; then
    first=$(head -n 1 "$tmp/fields")
    if [[ $first != "Status: "* ]]; then problem="Status: is missing or not the first field"
    else
      rstatus=${first#Status: }
      logged=$(logged_as "$rstatus")
      [[ -n $logged ]] || problem="not a result status: $rstatus"
    fi
  fi

  if [[ -z $problem ]]; then
    case $logged in
      completed)
        if [[ $art != "$expected" ]]; then problem="missing ===$expected=== block"
        elif [[ ! -s $tmp/artifact ]]; then problem="the ===$expected=== block is empty"
        elif [[ -s $tmp/questions ]]; then problem="### Questions appears without needs-input"
        fi ;;
      paused)
        if [[ $cmd == review ]]; then problem="the reviewer never returns needs-input"
        elif [[ -n $art ]]; then problem="artifact block without complete"
        elif [[ ! -s $tmp/questions ]]; then problem="needs-input without ### Questions"
        else
          types=$(vocab "Question tag")
          while IFS= read -r q; do
            q=${q%$'\r'}
            tag=${q#- [}; tag=${tag%%]*}
            if [[ $q != "- [$tag] "?* ]] || ! grep -qxF -- "$tag" <<< "$types"; then
              problem="question without a valid tag: $q"; break
            fi
          done < "$tmp/questions"
        fi ;;
      failed)
        if [[ -n $art ]]; then problem="artifact block without complete"
        elif [[ -s $tmp/questions ]]; then problem="### Questions appears without needs-input"
        fi ;;
    esac
  fi

  if [[ -z $problem ]]; then
    entry_specs "$cmd" "$logged" | awk -F'\t' '$1 != "Next step"' > "$tmp/specs"
    tail -n +2 "$tmp/fields" > "$tmp/entry"
    problem=$(check_fields "$tmp/specs" "$tmp/entry")
  fi

  if [[ -n $problem ]]; then
    logged=failed
    printf 'Reason: malformed result — %s\n' "$(printf '%s' "$problem" | tr -s ' \t' ' ' | sed 's/ $//')" > "$tmp/entry"
  fi

  case $logged in
    completed)
      case $cmd in
        plan) next="/ptah:implement $n" ;;
        implement) next="/ptah:review $n" ;;
        review)
          verdict=$(sed -n 's/^Verdict: //p' "$tmp/entry")
          if [[ $verdict == approved ]]; then next="none — review clean"; else next="/ptah:fix $n"; fi ;;
      esac
      cp "$tmp/artifact" "$SPECS/$folder/$expected" ;;
    paused) next="answer the open questions, then re-run /ptah:$cmd $n" ;;
    failed) next="re-run /ptah:$cmd $n" ;;
  esac
  printf 'Next step: %s\n' "$next" >> "$tmp/entry"

  printf 'Status: %s\n' "$logged"
  [[ $logged != completed ]] || printf 'Artifact: %s\n' "$SPECS/$folder/$expected"
  [[ -z $problem ]] || printf 'Malformed: yes — the raw result is in %s\n' "$result"
  printf '\nLogged:\n'
  append_entry "$folder" "/$cmd $logged" "$tmp/entry"
  if [[ $logged == paused ]]; then
    printf '\nQuestions:\n'
    cat "$tmp/questions"
  fi
}
