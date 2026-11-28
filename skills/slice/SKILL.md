---
name: slice
description: 'Splits a Ptah spec into vertical slices the user approves, each worked on its own, and writes a SLICE.md for each in slices/<nn>-<slug>/'
argument-hint: '[<spec-id>]'
disable-model-invocation: true
---

# /slice

Split a spec into vertical slices, get the user's approval on the list, and write one `SLICE.md` per slice. The slice folders, the `SLICE.md` format and slice state are defined in `../../guides/slices.md`. Read it before Step 1.

`RULES.md` is `../../RULES.md`. Read it before Step 1 unless its full text is already in your context.

## Step 1 — Resolve the spec

Resolve `<spec-id>` per `../../guides/spec-identifiers.md`. If `.ptah/specs/<feature-name>/SPEC.md` is empty or missing, stop: "No spec found for `<spec-id>`."

Slicing starts from a commit, because the approval may discard plans and summaries that describe uncommitted code. If `git status --porcelain` shows anything outside `.ptah/`, stop:

> "You have uncommitted work outside `.ptah/`. Commit or discard it first, then run `/ptah:slice <id>` again."

The step is done when you have the spec folder, its `SPEC.md` has content, and nothing outside `.ptah/` is uncommitted.

## Step 2 — Draft the slices

Read `SPEC.md` and see what the spec folder already holds: a flat spec's root `PLAN.md`, `IMPLEMENTATION-SUMMARY.md` and `REVIEW.md`, or an earlier slicing's folders and the state `LOGS.md` gives them.

A slice is a product cut: a behaviour that works end to end and can be checked, taken from the spec's user stories and use cases. Make each one **vertical**: a thin path through every layer it needs (data, backend, UI), so the first slice puts the core rules in front of a real database and screen. Slicing by layer delays integration until the last slice, so never do it. The one exception is a preparatory refactor slice that makes later slices easy. Each slice fits in one `/ptah:implement` run, one fresh context.

Look up in the code only the facts that shape the cut: which layers a story touches, and what already exists. How to build a slice belongs to `/ptah:plan`.

Give each slice a short title, **What to build** with the user stories it covers, and its **Criteria**: testable conditions, each one a spec acceptance criterion or the part of one that this slice proves. Write each slice **self-contained**, per the slices guide. Order the slices so each comes after every slice it builds on; among the slices free to go next, the riskiest rules come first.

The draft is done when every user story and acceptance criterion in `SPEC.md` is covered by at least one slice's **What to build** or **Criteria**, every slice is vertical (or the one preparatory refactor), fits one `/ptah:implement` run and is self-contained, and no slice builds on a later one.

## Step 3 — Get the list approved

Show the numbered list: each slice's title, what it builds, and its criteria. Name any user story or acceptance criterion the slices leave uncovered. Ask whether any slice is too big or too small, and whether to merge or split any.

When the spec folder already holds work, the list also says what the approval discards: existing slice folders with the plans, summaries and reviews in them, or on a flat spec the root `PLAN.md`, `IMPLEMENTATION-SUMMARY.md` and `REVIEW.md`. An existing slice that comes through unchanged can keep its folder, renamed if it's renumbered. Propose which new slices the committed code already delivers. The user agrees on them as part of the list, and they become `Done:`.

Revise the list from each reply and show it again. The step is done when the user approves the list as shown, with every user story and acceptance criterion covered.

## Step 4 — Write the slices

Delete what the approved list discards, then make `slices/` match it: one `slices/<nn>-<slug>/` per slice, holding its `SLICE.md` in the format from `../../guides/slices.md`. The step is done when nothing the list discards remains, `slices/` holds exactly the approved slices, numbered in order, and each `SLICE.md` says what the list said.

## Step 5 — Log and hand off

Append `/slice completed` to `LOGS.md` per `../../guides/logs-format.md`.

Hand off per `../../guides/result-format.md`, with `.ptah/specs/<feature-name>/slices/` as the artifact. Key facts: how many slices, and which are done. Add a `Slices` list, one line per slice with its number and title. The step is done when the hand-off lists every slice in `slices/`.
