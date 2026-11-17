## What this is

Ptah is a Claude Code plugin. The repo has no application code and no build, lint, or test tooling — it's Markdown prompts only. This repo does not use Ptah on itself.

`README.md` lists the commands. `RULES.md` holds the cross-cutting rules and its **Path conventions** maps the plugin's files; each guide in `guides/` opens with what it defines.

### Testing a change

- Load the plugin into a scratch project and run the commands: `claude --plugin-dir /path/to/ptah`.
- To test an edit to `RULES.md`, start a new session. Skills don't re-read `RULES.md` once its text is in context, so a session that already ran a command keeps following the old version.

## Design principles

The principles in `README.md` → **Principles** bind every edit. Building the prompts also follows these:

- **Every skill sets `disable-model-invocation: true`.**
- **Skill or subagent.** A new command dispatches a subagent when it must be isolated from the conversation (the reviewer), or when it explores heavily enough to fill the main context (the architect, the implementer). It runs as a skill in the main session when it needs the conversation or the user (questions, approvals, things that never reached `LOGS.md`), or when it mostly reads a few files in the spec folder.
- **Judgment for the agent, determinism for tooling.** Deterministic values (spec codes, `LOGS.md` entry ids and timestamps, commit hashes) come from shell commands pinned in the prompts, never from the model.
- **Project-agnostic.** No project names, ticket prefixes, or machine paths in prompts. Project-specific values belong in `.ptah/ptah.yml` or the target project's own `CLAUDE.md`.

## Claude Code constraints

- **Plugin paths.** Skills reference plugin files as `../../` from their own directory, which the harness tells the model when it loads a skill. Agents aren't told where they live, so they get the plugin root in their prompt, per `guides/delegated-work.md`. `RULES.md` and the guides link with paths relative to themselves.
- Keep Claude Code specifics confined to frontmatter, `$ARGUMENTS`, and the lines that dispatch a subagent, so the prompt bodies stay portable to other harnesses.

## Editing conventions

- **Change a field, status, or value everywhere at once.** Update `vocabulary.md` first, then `logs-format.md` (per-command fields), `result-format.md` (per-command table), the agent's result template, and the dispatching skill.
- **Define once, reference by name.** A fixed value lives only in `vocabulary.md`; a cross-cutting rule lives only in `RULES.md`; a paragraph two skills need goes in `RULES.md` or a guide. Skills point to sections by name ("per **Stop and ask** in `RULES.md`") instead of restating them. Renaming a `RULES.md` section means grepping `skills/` and `guides/` for it.
- **Agents don't read `RULES.md`.** What an agent needs goes in its own prompt or a guide it reads.
- **Read top to bottom.** A step never points ahead to a later step's content. Define what a step needs before or inside it; later steps may point back.
- **State current facts only.** Prompts and guides describe how Ptah works now — no "previously", "renamed from", or design history.

## Working on this repo

- Confirm the approach before multi-file changes; once confirmed, make all affected edits in one pass.
- Stay in scope. Flag a gap or deliberate omission you notice instead of silently fixing it.
- Windows checkouts may show every file as modified — use `git diff --ignore-cr-at-eol`.