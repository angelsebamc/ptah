---
name: slice
description: 'Splits a Ptah spec into vertical slices, each a behavior that works end to end and fits one /implement run, with blockers and testable criteria. Iterates on the list with the developer until approved, then creates a folder with a SLICE.md for each slice. A re-run revises the slices.'
argument-hint: '[<spec-id>]'
disable-model-invocation: true
---

# /slice

Split a spec into vertical slices, each in its own folder under `slices/`, so each one is planned, built, reviewed and accepted on its own.
`RULES.md` is `../../RULES.md`. Read it before Step 1 unless its full text is already in your context.

## Step 1 — Resolve the spec

`<spec-id>` = `$ARGUMENTS[0]`, if given. Resolve it per `../../guides/spec-identifiers.md`.

If `.ptah/specs/<feature-name>/SPEC.md` is empty or missing, stop:

> "No spec found for `<spec-id>`."

If the spec folder has a `PLAN.md`, stop:

> "Spec `<id>` is already planned as a whole (`PLAN.md`). Slicing comes before planning."

---

## Step 2 — Read the context

Read, per **Always read LOGS.md first** in `RULES.md`:

- `LOGS.md` in the spec folder, and every slice's `LOGS.md` if `slices/` exists
- `SPEC.md` — the user stories and use cases the slices are cut from
- every slice's `SLICE.md`, if `slices/` exists
- `refs/`

Then read `../../guides/slices.md`: **Slice folder**, the **SLICE.md** format and **Slice state** shape the draft.

If `slices/` exists, this is a **re-run**, which revises the slices:

- Only a slice whose folder holds nothing but `SLICE.md` may be renumbered, merged, split or dropped; any other keeps its number and its folder.
- An accepted slice stays as it is. When the user asks to change one, tell them the change reopens it, per **Reopening** in `../../guides/slices.md`, through `/ptah:plan <id> <n>`.
- New slices take numbers after the highest.

Look up in the code only the facts the slicing needs, such as which modules a flow touches or whether something a slice relies on already exists.

---

## Step 3 — Draft the slices

Each slice is a **tracer bullet**: a thin path through every layer it needs (data, backend, UI), cut from the spec's user stories and use cases, that works end to end and can be checked on the running app. Slice by behavior. Never slice by layer, because that puts off integration to the last slice; the one exception is a preparatory refactor slice that makes later slices easy.

- **Core first.** Order the slices so the rules everything else builds on are checked against the real app first.
- **One `/implement` run.** A slice fits in one fresh context. Split a slice that doesn't.
- **Blocked by** lists a slice only when this one couldn't be built without it.
- **Delivers** ends with the ids of the stories it covers.
- **Criteria** are conditions someone can check on the running result, specific to the slice.

The draft is done when every user story is covered by at least one slice, every slice fits one run, and every **Blocked by** entry passes that test.

---

## Step 4 — Get the list approved

Show the draft, each slice in the **SLICE.md** format. On a re-run, mark each slice `new`, `changed` or `unchanged`.

Then ask, all at once and numbered per **Stop and ask** in `RULES.md`, about anything you're unsure of: a slice that may be too large for one run, a blocker that may not be real, slices that may be better merged or split. Give your recommendation on each.

Revise the list with each reply and show it again. The step is done when the user says the list is approved.

---

## Step 5 — Write the slices

Write each approved slice's `SLICE.md` in its folder, per **Slice folder** in `../../guides/slices.md`, creating the folder for a new slice. On a re-run, also rename the folder of each renumbered slice and remove the folder of each dropped or merged one.

---

## Step 6 — Append to LOGS.md

Append `/slice completed` to the spec folder's `LOGS.md` per `../../guides/logs-format.md`. `Next step: /ptah:plan <id> <n>`, with `<n>` the lowest-numbered ready slice, per **Slice state** in `../../guides/slices.md`.

---

## Step 7 — Hand off to user

Hand off per `../../guides/result-format.md`, with a `Slices` list of one line per slice: `<n>. <title> — blocked by <numbers, or "none">`.
