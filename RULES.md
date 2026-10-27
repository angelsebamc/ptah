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
3. After each answer, the dispatcher appends a change entry recording it (`Trigger: user-request`, the tagged type, `What:` the answer as a one-line decision).
4. The dispatcher re-dispatches with the same prompt — just the folder path. The subagent finds the answers in `LOGS.md`, where they belong anyway.

Answers go through `LOGS.md` and never through the prompt, so a re-dispatch in a later session — after the main session ended mid-loop — works exactly the same way. And because the pause is a real command entry, `/ptah:resume` shows the spec as paused, with what it's blocked on.

Subagents can't spawn subagents, so they're always dispatched from the main session.

### Handling the result

Dispatching commands (`/plan`, `/implement`, `/review`) handle the subagent's result the same way. First check it against every rule in [`the result format`](${CLAUDE_PLUGIN_ROOT}/guides/result-format.md).

- **`complete`** — write the artifact block verbatim to the spec folder, then append `/<command> completed` per [`the logs format`](${CLAUDE_PLUGIN_ROOT}/guides/logs-format.md), copying the result's fields and adding `Next step:`.
- **`needs-input`** — run the loop above: append `/<command> paused` copying the result's fields verbatim, ask the `### Questions` one at a time in the order returned (reword if it reads better, but never answer, soften, or drop one), log each answer, then re-dispatch.
- **`error`, or a malformed result** — write no artifact, append `/<command> failed`, and hand off as failed. If the result was malformed, offer to show the raw response.

Then hand off per the result format.

---

## Logging discipline

While working on any spec, append **change entries** to the corresponding `LOGS.md` whenever a meaningful event happens mid-session — not just when a command completes.

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

Every spec folder created by `/ptah:spec` is named one of two ways:

- **From a ticket** — `<TICKET-ID>-<slug>`, e.g. `PROJ-45-add-csv-export`. The ticket id keeps its original casing; `<slug>` is built from the ticket title. A ticket id that is only digits is prefixed with its source, e.g. `github-123-fix-login-redirect`, so it can't collide with a spec number. Ticket specs take no number.
- **Without a ticket** — `ptah-<n>-<slug>`, e.g. `ptah-3-user-login`. `<n>` is a sequential integer from `specs.next_id`, unique per project; `<slug>` is built from the feature name given to `/ptah:spec`.

### Resolving an identifier

Every command that takes a `<spec-id>` accepts a bare number (`3`), a prefixed number (`ptah-3`), a ticket id (`PROJ-45`, `github-123`), or the full folder name. Matching is case-insensitive: `PROJ-45` and `proj-45` are the same spec. Resolve it in this order:

1. If it matches a folder name in `.ptah/specs/`, use it.
2. Otherwise, if it is a number or `ptah-<number>`, glob `.ptah/specs/ptah-<number>-*`.
3. Otherwise, treat it as a ticket id and glob `.ptah/specs/<spec-id>-*`.
4. If exactly one folder matches, use it. If more than one matches, stop, list them, and ask for the full folder name. If none matches, stop: "No spec found for `<spec-id>`."

Commands refer to the resolved folder as `<feature-name>`.

### Displaying an identifier

In output shown to the user — hand-offs, `Next:` lines, `/ptah:resume`'s header — show only the spec's **display id**, written `<id>`:

- A ticket spec shows its ticket id as written in the folder name — everything up to and including the first run of digits, e.g. `/ptah:plan PROJ-45`, `/ptah:plan github-123`.
- Any other spec shows only its number, e.g. `/ptah:plan 3`.

File paths the user is meant to open are the exception: they use the full folder name.

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
| `${CLAUDE_PLUGIN_ROOT}/guides/` | `vocabulary.md`, `result-format.md`, `logs-format.md`, `config.md` |
| `${CLAUDE_PLUGIN_ROOT}/skills/<command>/` | One skill per command, invoked as `/ptah:<command>` |
| `${CLAUDE_PLUGIN_ROOT}/agents/` | Subagents, dispatched as `ptah:architect`, `ptah:implementer`, `ptah:reviewer`. See **Delegated work** |

**Project files** are the work product, relative to the project root (the session's working directory):

| Location | Purpose |
|----------|---------|
| `.ptah/ptah.yml` | Project config, created by `/ptah:init`. Every key is documented in [`config`](${CLAUDE_PLUGIN_ROOT}/guides/config.md) |
| `.ptah/specs/<TICKET-ID>-<slug>/`, `.ptah/specs/ptah-<n>-<slug>/` | Per-feature work product (created by `/ptah:spec`) |