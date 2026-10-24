# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Ptah is a Claude Code **plugin** ("an agentic workflow from spec to PR"). The repo contains no application code, build, lint, or test tooling: everything is Markdown prompts plus a small hook. Editing Ptah means editing prompt files, and "testing" means loading the plugin into a Claude Code session (e.g. `claude --plugin-dir .` from another project) and running its commands.

## Layout and how the pieces connect

- `.claude-plugin/plugin.json` — plugin manifest (name `ptah`, so commands are `/ptah:<command>` and agents are `ptah:<agent>`).
- `hooks/hooks.json` → `hooks/session-start.sh` — on SessionStart, prints `RULES.md` into the session context. Claude Code does not substitute `${CLAUDE_PLUGIN_ROOT}` in hook output, so the script replaces the literal `${CLAUDE_PLUGIN_ROOT}` in `RULES.md` with the real path. Keep links in `RULES.md` written as `${CLAUDE_PLUGIN_ROOT}/...` for this to work.
- `RULES.md` — cross-cutting rules every command and subagent follows (read `LOGS.md` first, ask one question at a time, never chain into the next command, the subagent dispatch/question loop, logging discipline, spec-id resolution, path conventions).
- `guides/` — the single sources of truth that everything else references:
  - `vocabulary.md` — every fixed value (command/result statuses, spec states, change types/triggers, severities and finding codes, verdicts, fix modes). Values not listed there are errors, never coerced.
  - `result-format.md` — the `===RESULT=== … ===<ARTIFACT>.md=== … ===END===` format subagents return, malformed-result rules, and the user-facing hand-off format.
  - `logs-format.md` — the strict `LOGS.md` entry schema, per-command required fields in order, and change entries.
- `skills/<command>/SKILL.md` — one user-invoked command each (`disable-model-invocation: true`): `init`, `spec`, `plan`, `implement`, `review`, `fix`, `resume`.
- `agents/` — `architect`, `implementer`, `reviewer` subagents.

### Workflow

`/ptah:init` writes `.ptah/ptah.yml` in the target project. `/ptah:spec` creates `.ptah/specs/ptah-<n>-<slug>/` with `SPEC.md`, `LOGS.md`, `refs/`. Then `plan` → `implement` → `review` → `fix` (→ `review` again). `resume` orients a new session from `LOGS.md`.

`plan`, `implement`, and `review` are **thin dispatchers**: the skill resolves the spec id, dispatches the matching subagent with *only the folder path* as the prompt, validates the returned result against `result-format.md`, writes the artifact block verbatim (`PLAN.md`, `IMPLEMENTATION-SUMMARY.md`, `REVIEW.md`), and appends the `LOGS.md` entry. Subagents never write `LOGS.md` or spec-folder files. When a subagent returns `needs-input`, the dispatcher logs `paused`, asks the questions, records each answer as a change entry in `LOGS.md`, and re-dispatches with the same path — answers travel through `LOGS.md`, never the prompt. `spec`, `fix`, `init`, and `resume` run in the main session.

## Editing conventions

- Field names are shared across subagent results, `LOGS.md` entries, and hand-offs so data moves by copying. When adding or renaming a field, status, or value, update every place it appears together: `vocabulary.md`, `logs-format.md` (per-command fields), `result-format.md` (per-command table), the agent's result template, and the dispatching skill.
- Define a fixed value only in `vocabulary.md` and reference it from elsewhere; don't restate definitions.
- Plugin files reference each other via `${CLAUDE_PLUGIN_ROOT}/...`; project work product is always relative to the target project root (`.ptah/...`). Never mix the two roots.
- `vocabulary.md` mentions `document` and `status` commands that have no skill yet.
