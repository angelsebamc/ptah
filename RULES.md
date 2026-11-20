# Ptah workflow rules

Cross-cutting rules that apply to every Ptah command.

---

## Always read LOGS.md first

Before any work on a feature, read `LOGS.md` in its spec folder, even when you only mean to look at one file. It is the single source of truth for current state: what's done, what was decided, what's next. An entry named by a later `Corrects:` is superseded, so go by the correction.

---

## Stop and ask

When the spec or plan is ambiguous, contradictory, or underspecified, stop and ask the user a targeted question before going on; ask several at once, numbered. A guess made to keep momentum becomes a deviation that surfaces much later. When everything is clear, skip the questions and proceed.

Ask only what the repo can't answer. Before asking how something should behave, find how the closest existing equivalent in the codebase does it. When a question offers options, recommend that existing pattern, cited as `<file>:<line>`, or say why not. Flag a recommendation that rests only on how the code does it, so the user knows to apply product judgement.

When the user questions a design, check the code before defending it.

---

## Steps the user does in a tool

When the user makes a change themselves in a tool, give the target state as checks they can see. Then verify it against what the tool produced (its files, or a value the user reads back), never against their "done".

---

## Wait for the user

When a command's work is done, hand off and wait for the user to run the next command. Continue into the next command's work only when `.ptah/ptah.yml` allows that command to run it (see [`config`](./guides/config.md)).

---

## Artifact ownership

`SPEC.md` and `PLAN.md` are living artifacts: they state what should be true now. An edit rewrites the affected sections in place, without narrating what they replaced; a decision may cite the change entry behind it (`LOGS.md #<n>`). Every edit has a change entry whose `Impact:` names the file and the sections updated, and the step's own change entry counts. Once one of `PLAN.md`'s **Open questions** is answered, remove it from there, and write `none` once the list is empty.

Any step that makes the work contradict `SPEC.md` or `PLAN.md` updates that file in the same step. A `scope-change` updates `SPEC.md`, and `PLAN.md` if it exists.

`IMPLEMENTATION-SUMMARY.md` and `REVIEW.md` are records. `/implement` writes `IMPLEMENTATION-SUMMARY.md` and `/review` writes `REVIEW.md` on each pass; every other command only appends to them, as `/fix` does with its Fix Summary in `REVIEW.md`. `/fix` and changes between commands add each file they touch to `IMPLEMENTATION-SUMMARY.md` under **Changes after implementation** (replacing its `None`) as `` - `<path>` — <what changed> (<source>) ``, where `<source>` is `see change entry #<n>` or `fix <codes>`.

---

## Changes between commands

Outside `/implement` and `/fix`, edit source files only when the user asks for a change between commands, and handle the request by its kind.

A change that needs planning (a design decision, a change to the plan's architecture, work across many files), and any change asked for before `IMPLEMENTATION-SUMMARY.md` exists, goes into the artifacts only: update `SPEC.md` or `PLAN.md` per **Artifact ownership**, then hand off to `/ptah:plan <id>` if there's no `PLAN.md` yet, otherwise to `/ptah:implement <id>`.

Make any other change in this session. Update `SPEC.md` or `PLAN.md` per **Artifact ownership** if the change contradicts them, log a change entry, add each file it touches to `IMPLEMENTATION-SUMMARY.md` per **Artifact ownership** citing that entry, then hand off to `/ptah:review <id>`.

---

## Logging discipline

While working on a spec, append **change entries** to its `LOGS.md` as meaningful events happen mid-session, not only when a command completes.

### When to log

Log a change entry, without asking, whenever an event matches a change type in [`vocabulary`](./guides/vocabulary.md).

### When NOT to log

Keep the log to events that change the work. Routine steps stay out: reading files (`LOGS.md` included), running searches, asking the next question in a normal flow, fixing typos or formatting, reasoning that changes nothing, and anything a command's completion entry already captures. When a lookup changes a decision, log the decision, not the lookup.

---

## Reports and vocabulary

Every fixed value in Ptah (command statuses, result statuses, change types and triggers, review axes, finding kinds, verdicts, fix modes) is defined once, in [`vocabulary`](./guides/vocabulary.md). Use those values exactly; a value that isn't on its list is an error, never something to coerce.

Every final report follows [`the result format`](./guides/result-format.md), in markdown.

`LOGS.md` entries, results, and hand-offs share the same field names, so information moves between them by copying, not translating.

---

## Path conventions

Two roots, never mixed.

**Plugin files** ship with Ptah, relative to the plugin root:

| Location | Purpose |
|----------|---------|
| `RULES.md` | This file |
| `guides/` | `vocabulary.md`, `result-format.md`, `logs-format.md`, `config.md`, `spec-identifiers.md`, `base-branch.md`, `delegated-work.md`, `project-standards.md`, `project-hooks.md`, `code-smells.md` |
| `skills/<command>/` | One skill per command, invoked as `/ptah:<command>` |
| `agents/` | Subagents, dispatched as `ptah:architect`, `ptah:implementer`, `ptah:reviewer`. See [`delegated work`](./guides/delegated-work.md) |

**Project files** are the work product, relative to the project root (the session's working directory):

| Location | Purpose |
|----------|---------|
| `.ptah/ptah.yml` | Project config, created by `/ptah:init`. Every key is documented in [`config`](./guides/config.md) |
| `.ptah/specs/<TICKET-ID>-<slug>/`, `.ptah/specs/<repo>-<code>-<slug>/` | Per-feature work product (created by `/ptah:spec`) |
| `.ptah/reviews/<branch-folder>/` | A review of a branch with no Ptah spec: `REVIEW.md`, and `TICKET.md` when it reviews against a ticket (written by `/ptah:review`). `<branch-folder>` is the branch name with each `/` turned into `-`, then kebab-cased per `spec-identifiers.md` |
