# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Ptah is a Claude Code **plugin**: a spec-driven workflow for AI coding agents, from spec to PR. Ptah is the methodology; the agent harness and the LLM are underneath it. The repo has no application code and no build, lint, or test tooling — it's Markdown prompts plus one SessionStart hook. Editing Ptah means editing the instructions an agent follows. This repo does not use Ptah on itself.

### Testing a change

- Load the plugin into a scratch project and run the commands: `claude --plugin-dir /path/to/ptah`.
- Check the hook on its own: `CLAUDE_PLUGIN_ROOT=$PWD bash hooks/session-start.sh` — every `${CLAUDE_PLUGIN_ROOT}` in the output should be an absolute path.
- The hook runs only at session start, so a change to `RULES.md` or the hook needs a new session to show up.

## Layout

- `.claude-plugin/plugin.json` — manifest. Its name `ptah` namespaces everything: skills are `/ptah:<command>`, agents are `ptah:<agent>`.
- `hooks/hooks.json` → `hooks/session-start.sh` — prints `RULES.md` into the session context. Claude Code doesn't substitute `${CLAUDE_PLUGIN_ROOT}` in hook output, so the script does it. Keep links in `RULES.md` written as `${CLAUDE_PLUGIN_ROOT}/...`.
- `RULES.md` — cross-cutting rules every command and subagent follows: read `LOGS.md` first, stop and ask one question at a time, wait for the user, delegated work and result handling, logging discipline, spec identifiers, path conventions.
- `guides/` — single sources of truth:
  - `vocabulary.md` — every fixed value: command/result statuses, spec states, change types and triggers, severities and finding codes, verdicts, fix modes.
  - `result-format.md` — the subagent result (`===RESULT===` … `===<ARTIFACT>.md===` … `===END===`), malformed-result rules, and the user-facing hand-off.
  - `logs-format.md` — the `LOGS.md` entry schema, per-command fields in order, change entries.
- `skills/<command>/SKILL.md` — one user-invoked command each: `init`, `spec`, `plan`, `implement`, `review`, `fix`, `resume`.
- `agents/` — `architect` (plans), `implementer` (writes code), `reviewer` (read-only: `Read, Grep, Glob`).

## Workflow

```
/ptah:init → /ptah:spec → /ptah:plan → /ptah:implement → /ptah:review ⇄ /ptah:fix
```

- `init` writes `commands.fix` to `.ptah/ptah.yml` in the target project.
- `spec` creates `.ptah/specs/ptah-<n>-<slug>/`, numbered from `specs.next_id`, and fills `SPEC.md` one question at a time — optionally pre-filled from a ticket via an MCP source in `context_sources`.
- `plan`, `implement`, `review` are **thin dispatchers**. Each resolves the spec, dispatches its subagent with *only the folder path* as the prompt, validates the result, writes the artifact block verbatim (`PLAN.md`, `IMPLEMENTATION-SUMMARY.md`, `REVIEW.md`), and appends the `LOGS.md` entry. Shared handling lives in **Handling the result** in `RULES.md`; each skill states only its differences.
- On `needs-input`, the dispatcher logs `paused`, asks the questions one at a time, logs each answer as a change entry, and re-dispatches with the same path. Answers travel through `LOGS.md`, never the prompt — so a re-dispatch in a later session works the same way.
- `fix` applies `REVIEW.md` findings by code (`B1`, `M2`, …) in `auto`, `plan` (default), or `interactive` mode, then routes back to `review`. An `approved` review ends the pipeline.
- `resume` reads only `LOGS.md` and reports where a spec stands. It writes nothing.

## Design principles

These are why the files look the way they do. Keep them when editing.

- **One job per command.** `implement` doesn't review or open PRs; `review` never touches code. A new responsibility is a new command.
- **Never auto-advance.** Every skill sets `disable-model-invocation: true` and ends with a hand-off naming the next command. The user runs it.
- **Isolated review.** The reviewer gets a fresh context and the folder path only. An agent reviewing work from its own conversation keeps rationalizations that never reached the artifacts. Never pass a subagent conversation context, summaries, or explanations on anyone's behalf.
- **Judgment for the agent, determinism for tooling.** No scripts ship today, so deterministic steps are pinned down in the prompts instead: spec numbers come from `specs.next_id`, never from scanning folders, and are never reused; `LOGS.md` timestamps come from `date '+%Y-%m-%d %H:%M:%S'`, never from memory.
- **Hard failures over silent fallbacks.** A missing artifact, missing ticket, missing MCP server, malformed result, or value outside `vocabulary.md` stops the command. The dispatcher never patches or guesses at a malformed result — it logs `failed`.
- **Artifact preconditions.** Each command checks the previous phase's artifact exists and isn't empty before doing anything.
- **`LOGS.md` is the resume mechanism and the audit trail.** Strict schema so agents can parse it, bullets in plain language so a developer can trace the agent's reasoning.
- **Project-agnostic.** No project names, ticket prefixes, or machine paths in prompts. Project-specific values belong in `.ptah/ptah.yml` or the target project's own `CLAUDE.md`.

## Claude Code constraints

- `${CLAUDE_PLUGIN_ROOT}` is expanded in skill and agent content, not in hook output.
- Subagents can't talk to the user and can't spawn subagents. That's why dispatching happens only from the main session, and why questions come back as `needs-input`.
- Agents don't get the hook's context, so each agent reads `${CLAUDE_PLUGIN_ROOT}/RULES.md` itself in its Step 1.

## Editing conventions

- **Change a field, status, or value everywhere at once.** Field names are shared by subagent results, `LOGS.md` entries, and hand-offs so data moves by copying. Update `vocabulary.md` first, then `logs-format.md` (per-command fields), `result-format.md` (per-command table), the agent's result template, and the dispatching skill.
- **Define once, reference by name.** A fixed value lives only in `vocabulary.md`; a cross-cutting rule lives only in `RULES.md`. Skills point to sections by name ("per **Spec identifiers** in `RULES.md`") instead of restating them. Renaming a `RULES.md` section means grepping `skills/` and `agents/` for it.
- **Naming.** User-facing text (hand-offs, `Next:` lines, errors) uses `/ptah:<command> <n>` with the bare spec number. `LOGS.md` headings use the unprefixed `/<command>`. File paths the user opens use the full folder name.
- **Two roots, never mixed.** Plugin files via `${CLAUDE_PLUGIN_ROOT}/...`; work product relative to the target project root (`.ptah/...`).
- **State current facts only.** Prompts and guides describe how Ptah works now — no "previously", "renamed from", or design history.
- **Keep skills thin.** If two skills need the same paragraph, it belongs in `RULES.md` or a guide.

## Not built yet

- `/ptah:ship` — commit and open the PR, as its own command. When it lands, `approved`'s next step becomes `/ptah:ship <n>` in `vocabulary.md`, `logs-format.md`, and `skills/review/SKILL.md`.
- `/ptah:status` — overview of every spec's state (states are already defined in `vocabulary.md`).
- A second harness adapter (Devin). Keep Claude Code specifics confined to frontmatter, `${CLAUDE_PLUGIN_ROOT}`, `$ARGUMENTS`, and the hook, so the prompt bodies stay portable.

## Line endings

Commit with LF. Windows checkouts may show every file as modified — use `git diff --ignore-cr-at-eol`. `hooks/session-start.sh` must stay LF-only: bash fails on CRLF. `.gitattributes` pins `*.sh` to LF.

## Working on this repo

- Confirm the approach before multi-file changes; once confirmed, make all affected edits in one pass.
- Give one recommendation with the tradeoff, not a neutral list of options.
- Stay in scope. Flag a gap or deliberate omission you notice instead of silently fixing it.
- Short replies like "yes" or "do it" are go-aheads, not invitations to discuss further.
