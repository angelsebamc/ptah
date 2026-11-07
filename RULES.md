# Ptah workflow rules

Cross-cutting rules the agent applies regardless of which command is running. These apply to **every** Ptah command.

---

## Always read LOGS.md first

When working on any feature, read `LOGS.md` in the relevant spec folder before doing anything else. It is the single source of truth for current state — what's been done, what was decided, what's next. Never skip it, even when "just looking" at one specific file.

---

## Stop and ask, one question at a time

If anything in the spec or plan is ambiguous, contradictory, or underspecified, stop and ask the user a targeted question before proceeding. Ask one question at a time when there are several. Do not guess to keep momentum — guessing accumulates into deviations that surface much later.

If everything is clear, skip the clarifying step entirely and proceed.

---

## Wait for the user

Never continue into the next command's work. Hand off and wait for the user to run it.

---

## Logging discipline

While working on any spec, append **change entries** to the corresponding `LOGS.md` whenever a meaningful event happens mid-session — not just when a command completes.

### When to log

Log a change entry, without asking, whenever an event matches a change type in [`vocabulary`](./guides/vocabulary.md).

### When NOT to log

Routine work creates noise — do not log it:
- Reading files, running searches, asking the next clarifying question in a normal flow
- Fixing typos, formatting, or reformatting code
- Restating something already captured in a command's completion entry
- Internal reasoning steps that don't change anything
- Reading `LOGS.md`; only log if what it surfaced changed a decision (and then log the decision, not the lookup)

---

## Reports and vocabulary

Every fixed value in Ptah — command statuses, result statuses, spec states, change types and triggers, severities, verdicts, fix modes — is defined once, in [`vocabulary`](./guides/vocabulary.md). Commands use those values exactly; a value that isn't on its list is an error, never something to coerce.

Every final report follows [`the result format`](./guides/result-format.md), in markdown.

`LOGS.md` entries, results, and hand-offs share the same field names, so information moves between them by copying, not translating.

---

## Path conventions

Two roots, never mixed.

**Plugin files** ship with Ptah:

| Location | Purpose |
|----------|---------|
| `${CLAUDE_PLUGIN_ROOT}/RULES.md` | This file |
| `${CLAUDE_PLUGIN_ROOT}/guides/` | `vocabulary.md`, `result-format.md`, `logs-format.md`, `config.md`, `spec-identifiers.md`, `delegated-work.md`, `project-standards.md`, `project-hooks.md` |
| `${CLAUDE_PLUGIN_ROOT}/skills/<command>/` | One skill per command, invoked as `/ptah:<command>` |
| `${CLAUDE_PLUGIN_ROOT}/agents/` | Subagents, dispatched as `ptah:architect`, `ptah:implementer`, `ptah:reviewer`. See [`delegated work`](./guides/delegated-work.md) |

**Project files** are the work product, relative to the project root (the session's working directory):

| Location | Purpose |
|----------|---------|
| `.ptah/ptah.yml` | Project config, created by `/ptah:init`. Every key is documented in [`config`](./guides/config.md) |
| `.ptah/specs/<TICKET-ID>-<slug>/`, `.ptah/specs/<repo>-<code>-<slug>/` | Per-feature work product (created by `/ptah:spec`) |