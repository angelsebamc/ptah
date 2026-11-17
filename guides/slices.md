# Slices

Defines how a spec is split into slices: `SLICES.md`, slice folders, the slice number argument, slice state, reopening, picking a slice, the work folder, which logs a command reads, shared design, the slice review base, and slice numbers in hand-offs.

A spec is **sliced** when its folder has `SLICES.md`, written by `/ptah:slice`. A spec without it is **flat**: one `PLAN.md`, `IMPLEMENTATION-SUMMARY.md` and `REVIEW.md` at the spec root, and nothing else in this guide applies to it.

`<folder>` is the spec folder, `.ptah/specs/<feature-name>/`.

## Layout

```
<folder>/
├── SPEC.md                    the product contract
├── SLICES.md                  slice list: order, blocked by, delivers, criteria
├── LOGS.md                    entries that belong to no slice: /spec, /slice, the final /review and /fix
├── REVIEW.md                  final review of the whole feature
├── refs/
└── slices/
    ├── 01-root-batch/
    │   ├── PLAN.md
    │   ├── IMPLEMENTATION-SUMMARY.md
    │   ├── REVIEW.md
    │   └── LOGS.md            this slice's entries only
    └── 02-company-overrides/
```

## SLICES.md

```markdown
# SLICES — <feature-name>

## 1. <title>
- Blocked by: <none, or the comma-separated numbers of the lower-numbered slices that gate it>
- Delivers: <the behavior that works end to end once this slice is done> (<story ids, e.g. US1, US2>)
- Criteria: <testable condition>; <testable condition>
```

Slices are numbered from 1. `SLICES.md` holds no status.

## Slice folder

A slice's folder is `<folder>/slices/<nn>-<kebab>/`: `<nn>` is its number in two digits (`01`), `<kebab>` its title in kebab-case per `spec-identifiers.md`, cut at the last `-` before the 50th character when longer. A slice's folder is the one in `slices/` whose name starts with `<nn>-`, so a later title change doesn't rename it.

`/ptah:plan` creates a slice's folder the first time it plans that slice. No other command creates, renames or removes one.

## Slice number argument

A command that takes a slice number takes it right after the spec id: `/ptah:plan k3f9 2`. A positional of one or two digits is a slice number, never a spec id; when it's the first positional, the spec id was omitted.

A slice number on a flat spec stops the command:

> "Spec `<id>` has no slices. Leave out the slice number, or run `/ptah:slice <id>` first."

A number that isn't in `SLICES.md` stops it:

> "Slice `<n>` isn't in `SLICES.md` for `<id>`. Slices: <the numbers in SLICES.md>."

## Slice state

From the slice's own `LOGS.md`:

- **accepted** — it has an `/accept completed` entry, and no `reopen` change entry after the newest one.
- **ready** — not accepted, and every slice in its **Blocked by** is accepted.
- **blocked** — anything else.

## Reopening

A change to an accepted slice belongs to that slice, so the slice is reopened and goes back through plan, implement, review and accept. Ask:

> "Slice `<n>` is accepted. Reopen it? (yes / no)"

On yes, check `git status --porcelain`. If it shows uncommitted changes, stop:

> "You have uncommitted changes. Commit or stash them, then reopen slice `<n>`."

Otherwise append a `reopen` change entry to the slice's `LOGS.md`, with `What:` the change it's reopened for and `Base commit:` from `git rev-parse HEAD`, and go on.

## Picking the slice

On a sliced spec, once the spec is resolved:

- **A slice number was given** — use that slice.
  - **Blocked** → stop: "Slice `<n>` is blocked by slice <the unaccepted blockers>. Finish those first."
  - **Accepted** → ask whether to reopen it, per **Reopening**. On no, stop.
- **No slice number** — use the lowest-numbered ready slice. When every slice is accepted, `/ptah:review` and `/ptah:fix` work on the final review, on no slice. The other commands stop:
  > "Every slice of `<id>` is accepted. Next: `/ptah:review <id>` for the final review."

Before doing anything else, tell the user which slice was picked: "Using slice `<n>` — <title>." or "Every slice is accepted: final review."

## Work folder

The **work folder** is where a command writes its artifacts and its `LOGS.md` entries:

- **On a slice** — that slice's folder.
- **Otherwise** — `<folder>`: a flat spec, `/ptah:spec`, `/ptah:slice`, and the final `/ptah:review` and `/ptah:fix`.

Every entry goes in exactly one log: the work folder's `LOGS.md`. A change made on one slice that affects others is logged in that slice's log, and its `Impact:` names the others (`slice 3`).

## Which logs to read

Logs are never merged into one file. A command reads the logs it needs as one timeline, ordered by timestamp:

- **On a slice** — `<folder>/LOGS.md`, the slice's own `LOGS.md`, and the `LOGS.md` of each slice in its **Blocked by**.
- **The final review and its fix** — `<folder>/LOGS.md` and every slice's `LOGS.md`.

"The last command entry" always means the last one in the work folder's own `LOGS.md`.

## Shared design

A design decision lives in the plan of the first slice that needs it. Another slice's plan links to it by path and section (e.g. `slices/01-root-batch/PLAN.md` → **Data model**) and never copies it. A plan links only to slices in its own **Blocked by**. A change to a linked decision names the slices that link to it in its `Impact:`.

## Review base

A slice review covers everything that changed since the **review base**, committed or not, untracked included. The review base is the newest commit, by entry timestamp, recorded as `Commit:` on an `/accept completed` entry or `Base commit:` on a `reopen` entry, across every slice's `LOGS.md`. Before any slice is accepted, it's the commit the branch was cut from.

## Slices in hand-offs

On a slice, `<id>` in a hand-off's first line, its `Next:` line and a log entry's `Next step:` is the spec's display id followed by the slice number: `/review k3f9 2 completed`, `Next: /ptah:fix k3f9 2`.
