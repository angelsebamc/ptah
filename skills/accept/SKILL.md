---
name: accept
description: 'Accepts one slice of a sliced Ptah spec once its review is approved and the developer has looked at the result: shows its criteria and diff, commits it with an approved message (or waits for the developer''s own commit), and logs the commit.'
argument-hint: '[<spec-id>] [<slice>]'
disable-model-invocation: true
---

# /accept

Accept a slice: the developer has looked at the result and it meets the slice's criteria. Every accepted slice is a commit, and the next slice's review starts from it.
`RULES.md` is `../../RULES.md`. Read it before Step 1 unless its full text is already in your context.

## Step 1 — Resolve the spec and the slice

Take the slice number, if any, per **Slice number argument** in `../../guides/slices.md`. Resolve `<spec-id>` per `../../guides/spec-identifiers.md`.

If the spec has no `slices/` folder, stop:

> "Spec `<id>` has no slices. `/ptah:accept` accepts a slice; a spec without slices is ready for a PR once its review is approved."

If a slice number was given and that slice is accepted, per **Slice state** in `../../guides/slices.md`, stop:

> "Slice `<n>` is already accepted."

Otherwise pick the slice per **Picking the slice** in `../../guides/slices.md`.

Read the slice's `SLICE.md` and `LOGS.md`.

---

## Step 2 — Check the review

The slice's newest `/review completed` entry must have `Verdict: approved`, with no `/implement completed` entry after it. Otherwise stop:

> "Slice `<n>` has no approved review of its latest implementation. Run `/ptah:review <id> <n>`."

---

## Step 3 — Show the slice

Find the review base per **Review base** in `../../guides/slices.md`. Show:

- The slice's **Delivers** and **Criteria**, from its `SLICE.md`
- What changed since the review base: `git diff --stat <base>`, plus the untracked files `git status --porcelain` lists. Offer the full diff.

---

## Step 4 — Commit

Propose a commit message for the slice's changes. Follow the project's commit conventions, found per `../../guides/project-standards.md` (read only the parts about commits). The message names the ticket id, or the spec's display id for a spec without a ticket, and the slice number, and sums up what the slice delivers.

Ask which the user wants:

- **Commit, with your message or theirs** → stage every change since the review base (`git add -A`) and commit with that message. Handle every hook per `../../guides/project-hooks.md`. If the commit fails, show its error and stop. `<committer>` = `agent`.
- **They'll commit it** → wait for them to say it's done, then check it per **Steps the user does in a tool** in `RULES.md`. `<committer>` = `user`.

Then run `git status --porcelain`. While it shows changes, list them, ask the user to commit or stash them, and run it again. The step is done when the tree is clean.

---

## Step 5 — Append to LOGS.md

Append `/accept completed` to the slice's `LOGS.md` per `../../guides/logs-format.md`:

- `Commit:` from `git rev-parse HEAD`
- `Committed by:` `<committer>`
- `Next step:` `/ptah:plan <id> <m>` with `<m>` the lowest-numbered ready slice, per **Slice state** in `../../guides/slices.md`. When every slice is accepted, `/ptah:review <id>` for the final review.

---

## Step 6 — Hand off to user

Hand off per `../../guides/result-format.md`:

```
/accept <id> <n> completed
Artifact: commit `<short hash>` — <commit subject>
Slice <n> — <title> accepted
Next: <the entry's Next step:>
```
