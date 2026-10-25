#!/usr/bin/env bash
# Injects RULES.md into the session context.
# Hook output is not substituted by Claude Code, so the literal
# ${CLAUDE_PLUGIN_ROOT} references in RULES.md are expanded here.
set -euo pipefail

rules=$(cat "$CLAUDE_PLUGIN_ROOT/RULES.md")

printf 'Ptah plugin root: %s\n\n' "$CLAUDE_PLUGIN_ROOT"
printf '%s\n' "${rules//'${CLAUDE_PLUGIN_ROOT}'/"$CLAUDE_PLUGIN_ROOT"}"