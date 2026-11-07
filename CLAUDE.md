# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Ptah is a Claude Code **plugin**: a spec-driven workflow for AI coding agents, from spec to PR. Ptah is the methodology; the agent harness and the LLM are underneath it. The repo has no application code and no build, lint, or test tooling — it's Markdown prompts only. Editing Ptah means editing the instructions an agent follows. This repo does not use Ptah on itself.

### Testing a change

- Load the plugin into a scratch project and run the commands: `claude --plugin-dir /path/to/ptah`.
- Skills skip reading `RULES.md` when its full text is already in context, so test an edit to it in a new session.

## Layout

- `.claude-plugin/plugin.json` — manifest. Its name `ptah` namespaces everything: skills are `/ptah:<command>`, agents are `ptah:<agent>`.
- `RULES.md` — cross-cutting rules every command follows: read `LOGS.md` first, stop and ask one question at a time, wait for the user, logging discipline, reports and vocabulary, path conventions. Every skill reads it before its Step 1. Agents don't read it: their own prompts and the guides they read cover what they need.
- `guides/` — single sources of truth:
  - `vocabulary.md` — every fixed value: command/result statuses, spec states, change types and triggers, severities and finding codes, verdicts, fix modes.
  - `result-format.md` — the subagent result (`===RESULT===` … `===<ARTIFACT>.md===` … `===END===`), malformed-result rules, and the user-facing hand-off.
  - `logs-format.md` — the `LOGS.md` entry schema, per-command fields in order, change entries.
  - `config.md` — every `.ptah/ptah.yml` key, whether it's required, which command reads or writes it, and the required-keys check.
  - `spec-identifiers.md` — spec folder names, resolving a spec id and the omitted-id fallbacks, switching to and creating the spec's branch, the display id. Only the skills read it.
  - `delegated-work.md` — the folder-path-only prompt, the `needs-input` loop, and handling a subagent's result. Read by `plan`, `implement`, `review`.
  - `project-standards.md` — how a subagent finds the target project's standards, hook config included. Read by all three agents.
  - `project-hooks.md` — what to do when a hook blocks, asks about, or rewrites a tool call: comply, never route around it, ask only when complying needs a person. Read by the implementer and `fix`.
- `skills/<command>/SKILL.md` — one user-invoked command each: `init`, `spec`, `plan`, `implement`, `review`, `fix`, `resume`.
- `agents/` — `architect` (plans), `implementer` (writes code), `reviewer` (read-only: `Read, Grep, Glob, Skill`, and `Bash` for git).

## Workflow

```
/ptah:init → /ptah:spec → /ptah:plan → /ptah:implement → /ptah:review ⇄ /ptah:fix
```

- `init` writes `commands.fix` and the `tickets.server` MCP server to `.ptah/ptah.yml` in the target project, and offers to add `.ptah/` to `.git/info/exclude` so git ignores it for this developer only.
- `spec` takes a ticket id, a ticket URL, or nothing. It creates `.ptah/specs/<TICKET-ID>-<slug>/` for a ticket, or `.ptah/specs/<repo>-<code>-<slug>/` otherwise — `<repo>` from the git root folder, `<code>` 4 random characters from a pinned shell command, and the slug from a name the agent infers from the answers — and fills `SPEC.md` one question at a time, pre-filled from the ticket through `tickets.server` when there is one.
- `plan`, `implement`, `review` are **thin dispatchers**. Each resolves the spec, dispatches its subagent with *only the folder path* as the prompt, validates the result, writes the artifact block verbatim (`PLAN.md`, `IMPLEMENTATION-SUMMARY.md`, `REVIEW.md`), and appends the `LOGS.md` entry. Shared handling lives in **Handling the result** in `guides/delegated-work.md`; each skill states only its differences.
- On `needs-input`, the dispatcher logs `paused`, asks the questions one at a time, logs each answer as a change entry, and re-dispatches with the same path. Answers travel through `LOGS.md`, never the prompt — so a re-dispatch in a later session works the same way.
- `fix` applies `REVIEW.md` findings by code (`B1`, `M2`, …) in `auto`, `plan`, or `interactive` mode (from `commands.fix.mode`, or a flag), then routes back to `review`. An `approved` review ends the pipeline.
- `resume` reads only `LOGS.md` and reports where a spec stands. It writes no files.
- Every command that takes a spec id can omit it: the spec comes from the git branch name, then from this session's last hand-off, and otherwise the user picks from a list. When the spec isn't the current branch's, the command offers to switch to the spec's branch, or to create it from the remote's default branch when it has none and the working tree is clean.

## Design principles

These are why the files look the way they do. Keep them when editing.

- **Every stage writes an artifact the next stage reads.** The intent (the ticket), `SPEC.md`, `PLAN.md`, the diff with `IMPLEMENTATION-SUMMARY.md`, and `REVIEW.md`, tied together by `LOGS.md`, are the audit trail. Stages share nothing but the spec folder and the code. The other principles follow from this one.
- **One job per command.** `implement` doesn't review or open PRs; `review` never touches code. A new responsibility is a new command.
- **Never auto-advance.** Every skill sets `disable-model-invocation: true` and ends with a hand-off naming the next command. The user runs it.
- **Isolated review.** The reviewer gets a fresh context and the folder path only. An agent reviewing work from its own conversation keeps rationalizations that never reached the artifacts. Never pass a subagent conversation context, summaries, or explanations on anyone's behalf.
- **Judgment for the agent, determinism for tooling.** No scripts ship today, so deterministic steps are pinned down in the prompts instead: spec codes and `LOGS.md` timestamps come from pinned shell commands, never from the model.
- **Hard failures over silent fallbacks.** A missing artifact, missing ticket, missing MCP server, malformed result, or value outside `vocabulary.md` stops the command. The dispatcher never patches or guesses at a malformed result — it logs `failed`.
- **Artifact preconditions.** Each command checks the previous phase's artifact exists and isn't empty before doing anything.
- **`LOGS.md` is the resume mechanism and the audit trail.** Strict schema so agents can parse it, bullets in plain language so a developer can trace the agent's reasoning.
- **Project-agnostic.** No project names, ticket prefixes, or machine paths in prompts. Project-specific values belong in `.ptah/ptah.yml` or the target project's own `CLAUDE.md`.

## Claude Code constraints

- `${CLAUDE_PLUGIN_ROOT}` is expanded in skill and agent content, not in files read at runtime such as `RULES.md` and the guides. The agent resolves those links against the expanded path it read the file from.
- Subagents can't talk to the user and can't spawn subagents. That's why dispatching happens only from the main session, and why questions come back as `needs-input`.

## Editing conventions

- **Change a field, status, or value everywhere at once.** Field names are shared by subagent results, `LOGS.md` entries, and hand-offs so data moves by copying. Update `vocabulary.md` first, then `logs-format.md` (per-command fields), `result-format.md` (per-command table), the agent's result template, and the dispatching skill.
- **Define once, reference by name.** A fixed value lives only in `vocabulary.md`; a cross-cutting rule lives only in `RULES.md`. Skills point to sections by name ("per **Stop and ask** in `RULES.md`") instead of restating them. Renaming a `RULES.md` section means grepping `skills/` and `agents/` for it.
- **Naming.** User-facing text (hand-offs, `Next:` lines, errors) uses `/ptah:<command> <id>` with the spec's display id: the ticket id, or the bare spec code. `LOGS.md` headings use the unprefixed `/<command>`. File paths the user opens use the full folder name.
- **Two roots, never mixed.** Plugin files via `${CLAUDE_PLUGIN_ROOT}/...`; work product relative to the target project root (`.ptah/...`).
- **State current facts only.** Prompts and guides describe how Ptah works now — no "previously", "renamed from", or design history.
- **Keep skills thin.** If two skills need the same paragraph, it belongs in `RULES.md` or a guide.

## Not built yet

- `/ptah:ship` — commit and open the PR, as its own command. When it lands, `approved`'s next step becomes `/ptah:ship <id>` in `vocabulary.md`, `logs-format.md`, and `skills/review/SKILL.md`.
- `/ptah:status` — overview of every spec's state (states are already defined in `vocabulary.md`).
- A second harness adapter (Devin). Keep Claude Code specifics confined to frontmatter, `${CLAUDE_PLUGIN_ROOT}`, and `$ARGUMENTS`, so the prompt bodies stay portable.

## Line endings

Commit with LF. Windows checkouts may show every file as modified — use `git diff --ignore-cr-at-eol`.

## Working on this repo

- Confirm the approach before multi-file changes; once confirmed, make all affected edits in one pass.
- Give one recommendation with the tradeoff, not a neutral list of options.
- Stay in scope. Flag a gap or deliberate omission you notice instead of silently fixing it.
- Short replies like "yes" or "do it" are go-aheads, not invitations to discuss further.