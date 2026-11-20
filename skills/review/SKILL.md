---
name: review
description: 'Reviews code on three axes (spec, standards, correctness) through isolated, read-only reviewer subagents in parallel, and writes REVIEW.md with coded defects and judgements and a verdict. Reviews against the Ptah spec; with no Ptah spec, against the branch''s ticket, or the branch alone on standards and correctness. Use only when the user asks to review a Ptah spec, a ticket''s branch, or the current branch, or when /ptah:implement runs it because commands.implement.review is true: each run costs up to three subagents.'
argument-hint: '[<spec-id> | <ticket-id>] [--base <ref>]'
---

# /review

Review the code on the axes its review target needs — spec, standards, correctness — and write `REVIEW.md`.

`RULES.md` is `../../RULES.md`. Read it before Step 1 unless its full text is already in your context.

`/review` is a thin dispatcher: the review happens in isolated `reviewer` subagents, one per axis, per `../../guides/delegated-work.md`.

## Step 1 — Parse command arguments

The raw arguments are `$ARGUMENTS`, trimmed. A `--base <ref>` pair anywhere in them sets `<base-ref>` to `<ref>`; take both tokens out. What's left is either empty or one token, `<spec-id>`. Anything else, including a `--base` with no ref after it, is a usage error: show these examples and stop.
- `/ptah:review`: the spec, ticket or branch the current branch names
- `/ptah:review k3f9`: the spec `k3f9`
- `/ptah:review PROJ-45`: the spec for `PROJ-45`, or with no Ptah spec, the current branch against ticket `PROJ-45`
- `/ptah:review --base develop`: compare against `develop` instead of the branch this one was cut from

---

## Step 2 — Resolve the review target

The **review target** is what the code is reviewed against, and it decides which axes run:

| Target | Reviews against | Axes |
|---|---|---|
| `spec` | The Ptah spec's `SPEC.md` | `spec`, `standards`, `correctness` |
| `ticket` | A ticket, saved as `TICKET.md` | `spec`, `standards`, `correctness` |
| `branch` | Nothing | `standards`, `correctness` |

`<branch>` is the current branch.

**With a `<spec-id>`**, look for the spec per **Resolving an identifier** in `../../guides/spec-identifiers.md`. A match makes the target `spec`, and that guide goes on to offer the spec's branch. No match doesn't stop yet: if `<spec-id>` is shaped like a ticket id, per **Ticket ids** in that guide, the target is `ticket`, with `<ticket-id>` = `<spec-id>` uppercased, from the argument. Otherwise stop: "No spec found for `<spec-id>`."

**Without one**, try the branch and this session's last hand-off per **When the identifier is omitted** in that guide, but never ask the user to pick a spec: a review can run without one. If either names a spec, resolve it per **Resolving an identifier** and the target is `spec`. If neither does:

- On a detached `HEAD`, stop: "Check out a branch, or pass a spec id."
- If the branch names a ticket, per **A ticket id from the branch** in that guide, the target is `ticket`, with `<ticket-id>` from the branch.
- Otherwise the target is `branch`.

On `spec`, if `.ptah/specs/<feature-name>/IMPLEMENTATION-SUMMARY.md` is empty or missing, stop:

> "No implementation found for `<spec-id>`. Run `/ptah:implement <id>` first."

This only checks that the implementation happened. The reviewers never see `IMPLEMENTATION-SUMMARY.md`.

`<review-folder>` is `.ptah/specs/<feature-name>/` on `spec`, otherwise `.ptah/reviews/<branch-folder>/` per **Path conventions** in `RULES.md`.

---

## Step 3 — Load the ticket (`ticket` only)

Fetch `<ticket-id>` with the MCP tools of `<server>`, the `tickets.server` in `.ptah/ptah.yml`.

If the ticket can't be loaded, where the id came from decides what happens. An id the user passed is a hard stop, with the message that fits:

- "No ticket server is set for this project. Run `/ptah:init` to choose one."
- "MCP server `<server>` isn't available. Install or enable it, or run `/ptah:init` to choose another."
- "Ticket `<ticket-id>` wasn't found on `<server>`."

An id read from the branch name was only a guess, so the target becomes `branch`. Say why and go on to Step 4: "Branch `<branch>` names ticket `<ticket-id>`, but <no ticket server is set | MCP server `<server>` isn't available | it wasn't found on `<server>`>. Reviewing the branch without a spec."

Once the ticket is loaded, write `<review-folder>TICKET.md`, replacing any earlier one:

````
# TICKET — <ticket-id>: <ticket title>

**Source:** [<ticket-id>](<ticket-url>)

## Description
<the ticket's description, verbatim>

## Acceptance criteria
- <each acceptance criterion the ticket states, verbatim, in order>
````

Copy only the criteria the ticket states. With none, the section is `None.`. Never derive criteria from the description.

---

## Step 4 — Resolve the base

Tell the user what's being reviewed. On `spec`, **When the identifier is omitted** in `../../guides/spec-identifiers.md` already covers it. On `ticket`: "No Ptah spec for branch `<branch>`. Reviewing it against ticket `<ticket-id>`." On `branch`, unless Step 3 already said why: "No spec for branch `<branch>`. Reviewing the branch without a spec."

Then resolve `<base>` and its `<source>` per **Resolving the base** in `../../guides/base-branch.md`, with `<base-ref>` as `--base` if Step 1 set it. On `ticket` or `branch`, stop if there are no changes per **The changes** in that guide: "No changes on `<branch>` against `<base>`."

---

## Step 5 — Dispatch the reviewers

Invoke the `ptah:reviewer` subagent once for each of the target's axes from Step 2, all in one message, in the foreground. Each prompt is **only** these lines, with `<plugin-root>` per `../../guides/delegated-work.md` and `<first line>` from the target:

```
<first line>
Plugin root: <plugin-root>
Axis: <axis>
Base: <base>
```

| Target | `<first line>` |
|---|---|
| `spec` | `Review the Ptah spec at <review-folder>` |
| `ticket` | `Review the branch <branch> against the ticket at <review-folder>TICKET.md` |
| `branch` | `Review the branch <branch>, which has no spec` |

---

## Step 6 — Check the results

Check each result against every rule in `../../guides/result-format.md`. A reviewer's result is also malformed if its `Axis:` isn't the axis it was dispatched with, its status is anything but `complete` or `error`, or its codes don't use its axis's letter.

The review goes on only when every axis returned a well-formed `complete`. A review missing an axis would look complete when it isn't, so if any result is `error` or malformed, write no `REVIEW.md`. On `spec`, append `/review failed` per `../../guides/logs-format.md`, with a `Reason:` that names each failed axis and why. Hand off as failed, naming the same, and if a result was malformed, offer to show the raw response.

---

## Step 7 — Write `REVIEW.md`

Write `<review-folder>REVIEW.md`, replacing any earlier one:

````
# REVIEW — <feature-name on spec, otherwise branch>

Compared against `<base>` (<source>).
Reviewed against: <`SPEC.md` | ticket [<ticket-id>](<ticket-url>), saved in `TICKET.md` | no spec>

## Summary
<2–3 sentences across the axes: is the code solid, and what's the main concern?>
- Spec: <d> defects, <j> judgements
- Standards: <d> defects, <j> judgements
- Correctness: <d> defects, <j> judgements

## Spec
<the spec axis's ===FINDINGS=== block>

## Standards
<the standards axis's ===FINDINGS=== block>

## Correctness
<the correctness axis's ===FINDINGS=== block>

## Acceptance criteria check
- [x] <criterion> — met
- [ ] <criterion> — <partial | missing> (see <code>)

## Verdict
<`fix-needed` — <n> defects | `approved` — no defects>
````

On `branch`, leave out the Summary's Spec line and the **Acceptance criteria check**, and the Spec section reads: "No spec available: the spec axis was skipped."

**Findings** go in as each axis returned them, never re-ranked across axes. The one change allowed is for a duplicate: when two findings on different axes describe the same problem at the same code, keep both and add `Same as: <code>` as the last line of the one on the later axis (spec, then standards, then correctness), naming the earlier one, so it gets fixed once.

**Acceptance criteria check** lists every acceptance criterion in `SPEC.md`, or in `TICKET.md` on `ticket`, in order. A criterion named on a spec finding's `Criterion:` line takes that line's status and the finding's code; every other criterion is met. If the number met doesn't match the spec axis's `Acceptance criteria:` field, the spec result is malformed: go back to Step 6's failure. A ticket with no acceptance criteria gets the single line "The ticket lists no acceptance criteria."

**Verdict** is per **Review verdict** in `../../guides/vocabulary.md`, from the defects across all the axes. Its `<n>` leaves out a defect whose `Same as:` names another defect; the Summary's per-axis counts still include it.

`REVIEW.md` is done when every finding from every axis appears exactly once, in the order its axis returned it, and the counts and verdict agree with them.

---

## Step 8 — Log and hand off

On `spec`, append `/review completed` per `../../guides/logs-format.md`: each axis's counts from its result, `Acceptance criteria:` from the spec axis, the verdict, and `Next step:` per **Review verdict** in `../../guides/vocabulary.md`.

Hand off per `../../guides/result-format.md`, with the base among the key facts, plus `Ticket: <ticket-id>` on `ticket`. On `ticket` or `branch` there's no spec for `/ptah:fix` to work from, so `Next:` is `fix the defects, then /ptah:review` on `fix-needed` and `none — review clean` on `approved`.
