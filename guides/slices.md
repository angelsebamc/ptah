# Slices

A large spec can be split into **slices**: vertical cuts of the feature, worked one at a time in order, each planned, built and reviewed on its own. `/ptah:slice` creates them. This guide defines how every other command tells where a sliced spec stands.

## Sliced or flat

A spec is **sliced** when its folder holds a `slices/` folder. Otherwise it's **flat**, with one `PLAN.md`, `IMPLEMENTATION-SUMMARY.md` and `REVIEW.md` at its root.

```
.ptah/specs/<spec>/
├── SPEC.md                    one contract per spec
├── LOGS.md                    the only log
├── REVIEW.md                  the final review of the whole feature
└── slices/
    ├── 01-root-batch/
    │   ├── SLICE.md
    │   ├── PLAN.md
    │   ├── IMPLEMENTATION-SUMMARY.md
    │   └── REVIEW.md
    └── 02-company-overrides/
```

Each slice folder is `slices/<nn>-<slug>/`: `<nn>` is the slice's number in two digits, which sets its order, and `<slug>` is its title in kebab-case per [`spec-identifiers.md`](./spec-identifiers.md). Slice `<n>` is the folder numbered `<n>`. The `slices/` folder is the list of slices; no other file lists them.

## SLICE.md

```markdown
# SLICE <n> — <title>

## Delivers
<the behaviour that works end to end once the slice is done>
Covers: <the user stories it covers, e.g. US1, US3 (create only)>

## Criteria
- <a testable condition the slice meets>
```

## Slice state

A slice's state comes from `LOGS.md`, never from its folder. Every entry that belongs to a slice carries `Slice: <n>`, per [`logs-format.md`](./logs-format.md). Go only by entries after the newest `/slice completed`: a re-slice renumbers the slices, so older tags name old numbers.

A slice is **finished** when the newest `/slice completed` lists it in `Done:`, or when its newest `/review completed` has `Verdict: approved` and no later entry for that slice changed code. A `/fix completed` after an approved review fixes only judgements, so it keeps the slice finished.

The **current slice** is the highest-numbered slice with a `/plan` entry. With none, it's the lowest-numbered slice that isn't finished. A finished current slice stays current until `/plan` moves on to the next one.

The **feature is finished** when every slice is. From then on, `/review` reviews the whole feature, the **final review**: the whole branch, against `SPEC.md` alone.

The **work folder** is where a command reads and writes `PLAN.md`, `IMPLEMENTATION-SUMMARY.md` and `REVIEW.md`: the current slice's folder, the spec folder for the final review, and the spec folder on a flat spec.

## Base commit

The first `/plan completed` of a slice records `Base commit:`, the commit the slice starts from. A slice review covers the changes since that commit, per **The changes** in [`base-branch.md`](./base-branch.md).

## Shared design

A design decision lives in the plan of the first slice that needs it. Later slices' plans link to it by path and section, and never copy it.

## Changes across slices

A change to an earlier, finished slice is work in the current slice: its `Impact:` names the earlier slice, and the earlier slice's `SLICE.md` or `PLAN.md` is updated if the change contradicts them.

A change that affects a later slice updates that slice's `SLICE.md` in the same step. When a change adds a user story no slice covers, the hand-off recommends running `/ptah:slice` again.
