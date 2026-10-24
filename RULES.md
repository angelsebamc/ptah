# Ptah workflow rules

Cross-cutting rules the agent applies regardless of which command is running. These apply to **every** Ptah command.

---

## Always read LOGS.md first

When working on any feature, read `LOGS.md` in the relevant spec folder before doing anything else. It is the single source of truth for current state — what's been done, what was decided, what's next. Never skip it, even when "just looking" at one specific file.

---

## Stop and ask, one question at a time

If anything in the spec or plan is ambiguous, contradictory, or underspecified, stop and ask the user a targeted question before proceeding. Ask one question at a time when there are several. Do not guess to keep momentum — guessing accumulates into deviations that surface much later.

This applies before:
- Writing any plan (`/plan`)
- Writing any code (`/implement`)
- Applying any fix (`/fix`)

If everything is clear, skip the clarifying step entirely and proceed.

---

## Wait for the user

Never continue into the next command's work. Hand off and wait for the user to run it.

---

## Delegated work

- **The prompt is the folder path, nothing else.** The subagent reads `SPEC.md`, `PLAN.md`, `LOGS.md`, `refs/`. The dispatcher never summarizes the conversation or explains anything on the user's behalf.

Subagents can't talk to the user, so **Stop and ask** becomes a loop:

1. The subagent hits something it would normally ask about. It stops and returns its questions, each tagged with the change-entry type the answer would be (`decision`, `deviation`, `scope-change`) — result status `needs-input`.
2. The dispatcher logs a `/<command> paused` command entry, then asks the questions one at a time.
3. After each answer, the dispatcher logs a change entry recording it with `log change` (`Trigger: user-request`, the tagged type, `What:` the answer as a one-line decision).
4. The dispatcher re-dispatches with the same prompt — just the folder path. The subagent finds the answers in `LOGS.md`, where they belong anyway.

Answers go through `LOGS.md` and never through the prompt, so a re-dispatch in a later session — after the main session ended mid-loop — works exactly the same way. And because the pause is a real command entry, `/ptah:resume` shows the spec as paused, with what it's blocked on.

Subagents can't spawn subagents, so they're always dispatched from the main session.

### Handling the result

Dispatching commands (`/plan`, `/implement`, `/review`) handle the subagent's result the same way:

1. Write the subagent's final message, exactly as returned, to `.ptah/specs/<feature-name>/.result.md`, replacing any earlier one. Don't fix, trim, or reformat it.
2. Run `apply-result <command> <n>`. It checks the result against [`the result format`](${CLAUDE_PLUGIN_ROOT}/guides/result-format.md), writes the artifact, and appends the `LOGS.md` entry, `Next step:` included. Never write either yourself.
3. Act on the `Status:` it prints:
   - **`completed`** — hand off with the printed `Artifact:` and `Next step:`.
   - **`paused`** — run the loop above with the printed `Questions:`: ask them one at a time in that order (reword if it reads better, but never answer, soften, or drop one), log each answer, then re-dispatch.
   - **`failed`** — hand off as failed with the logged `Reason:`. If it printed `Malformed: yes`, offer to show the raw response from `.result.md`.

Then hand off per the result format.

---

## Logging discipline

While working on any spec, append **change entries** to the corresponding `LOGS.md` with `log change` whenever a meaningful event happens mid-session — not just when a command completes.

### When to log

Log a change entry, without asking, whenever an event matches a change type in [`vocabulary`](${CLAUDE_PLUGIN_ROOT}/guides/vocabulary.md).

### When NOT to log

Routine work creates noise — do not log it:
- Reading files, running searches, asking the next clarifying question in a normal flow
- Fixing typos, formatting, or reformatting code
- Restating something already captured in a command's completion entry
- Internal reasoning steps that don't change anything
- Reading `LOGS.md`; only log if what it surfaced changed a decision (and then log the decision, not the lookup)

---

## Spec identifiers

Every spec folder created by `/ptah:spec` is named `ptah-<n>-<slug>`, e.g. `ptah-3-user-login`.

- `<n>` — a sequential integer, unique per project
- `<slug>` — a kebab-case version of the feature name given to `/ptah:spec`

### Resolving an identifier

Every command that takes a `<spec-id>` accepts a bare number (`3`), a prefixed number (`ptah-3`), or the full folder name (`ptah-3-user-login`). Resolve it with `resolve <spec-id>`, which prints the folder name: an exact folder name match first, then the one folder matching `ptah-<n>-*`. If it prints `No spec found for <spec-id>.`, stop with that message.

Commands refer to the resolved folder as `<feature-name>`.

### Displaying an identifier

In output shown to the user — hand-offs, `Next:` lines, `/ptah:resume`'s header — show **only the number**, e.g. `/ptah:plan 3`. File paths the user is meant to open are the exception: they use the full folder name.

---

## Ptah script

Deterministic steps — spec numbers, spec resolution, result checking, `LOGS.md` entries — are done by the Ptah script, never by hand. Run it from the project root with the Bash tool:

```
bash "${CLAUDE_PLUGIN_ROOT}/scripts/ptah" <subcommand> ...
```

| Subcommand | Does |
|---|---|
| `new-spec <feature-name>` | Takes the next number from `specs.next_id`, creates `.ptah/specs/ptah-<n>-<slug>/`, bumps the counter. Prints `<n> <folder>` |
| `resolve <spec-id>` | Prints the spec's folder name |
| `apply-result <command> <n>` | Checks `.result.md`, writes the artifact, appends the command entry. See **Handling the result** |
| `log command <n> <command> <status> '<Field>: <value>'...` | Appends a command entry. Fields in the order `logs-format.md` lists them, `Next step:` last |
| `log change <n> <command> '<Field>: <value>'...` | Appends a change entry |
| `resume <spec-id>` | Prints the last `LOGS.md` entry as one line |

- Pass each field as its own single-quoted argument. Inside it, write a `'` as `'\''`.
- A non-zero exit means nothing was written. Relay the message and stop — never work around the script or write what it refused.

---

## Reports and vocabulary

Every fixed value in Ptah — command statuses, result statuses, spec states, change types and triggers, severities, verdicts, fix modes — is defined once, in [`vocabulary`](${CLAUDE_PLUGIN_ROOT}/guides/vocabulary.md). Commands and subagents use those values exactly; a value that isn't on its list is an error, never something to coerce.

Every final report follows [`the result format`](${CLAUDE_PLUGIN_ROOT}/guides/result-format.md), in markdown.

`LOGS.md` entries, results, and hand-offs share the same field names, so information moves between them by copying, not translating.

---

## Path conventions

Two roots, never mixed.

**Plugin files** ship with Ptah:

| Location | Purpose |
|----------|---------|
| `${CLAUDE_PLUGIN_ROOT}/RULES.md` | This file. Injected into every session by `hooks/session-start.sh` |
| `${CLAUDE_PLUGIN_ROOT}/guides/` | `vocabulary.md`, `result-format.md`, `logs-format.md` |
| `${CLAUDE_PLUGIN_ROOT}/skills/<command>/` | One skill per command, invoked as `/ptah:<command>` |
| `${CLAUDE_PLUGIN_ROOT}/agents/` | Subagents, dispatched as `ptah:architect`, `ptah:implementer`, `ptah:reviewer`. See **Delegated work** |
| `${CLAUDE_PLUGIN_ROOT}/scripts/ptah` | The Ptah script. See **Ptah script** |

**Project files** are the work product, relative to the project root (the session's working directory):

| Location | Purpose |
|----------|---------|
| `.ptah/ptah.yml` | Project config: `specs.next_id`, `commands.fix`, `context_sources` |
| `.ptah/specs/ptah-<n>-<slug>/` | Per-feature work product (created by `/ptah:spec`) |
| `.ptah/specs/ptah-<n>-<slug>/.result.md` | The last subagent result, raw. Read by `apply-result` |
