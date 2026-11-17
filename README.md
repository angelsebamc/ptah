<p align="center">
  <img src="assets/logo.svg" alt="Ptah logo" width="140">
</p>

<h1 align="center">Ptah</h1>

<p align="center"><b>Conceived as a spec. Spoken into code.</b></p>

> [!NOTE]
> Ptah is a work in progress. Skills, files and config can change at any time.

In Egyptian mythology, Ptah is the creator god of Memphis, patron of craftsmen, architects and builders. According to the myth, he brought the world into being by conceiving it in his heart and speaking it with his tongue. Ptah, the workflow, does the same with your code: every feature is conceived as a spec, takes shape in a plan, and comes into being by the hand of an agent.

Ptah is a Claude Code plugin. You write a spec, and Ptah plans, implements, reviews and fixes it one step at a time. Every step leaves a file you can read in `.ptah/specs/<spec>/`.

![The Ptah workflow](assets/workflow.svg)

## Install

```sh
git clone https://github.com/angelsebamc/ptah.git
cd your-project
claude --plugin-dir /path/to/ptah
```

## Use

Run these inside Claude Code, in your project:

| Command | What it does | Writes |
|---------|--------------|--------|
| `/ptah:init` | One-time setup: fix defaults and your ticket server (optional) | `.ptah/ptah.yml` |
| `/ptah:spec [ticket]` | Grills you about the feature, looking facts up in the code, then writes the spec. Pass a ticket id or URL to start from it. | `SPEC.md` |
| `/ptah:slice` | Splits a large spec into vertical slices, with you (optional) | `SLICES.md` |
| `/ptah:plan` | Writes the technical plan | `PLAN.md` |
| `/ptah:implement` | Writes the code from the plan | code + `IMPLEMENTATION-SUMMARY.md` |
| `/ptah:review` | Reviews the code in a fresh context | `REVIEW.md` |
| `/ptah:fix` | Fixes the review findings, then run `/ptah:review` again (optional after an `approved` review) | Fix Summary in `REVIEW.md` |
| `/ptah:accept` | Accepts a slice once you've looked at the result, and commits it | a commit |
| `/ptah:resume` | Shows where a spec stands | nothing |

When a review comes back `approved`, the work is ready for a PR.

You can leave out the spec id: Ptah takes it from your git branch, or asks you to pick one. If you're not on the spec's branch, Ptah offers to switch to it, or to create it when it doesn't exist yet.

Everything that happens is logged in the spec's `LOGS.md`. Starting a new session? Run `/ptah:resume`.

### Slices

For a large feature, run `/ptah:slice` after `/ptah:spec` to split the spec into vertical slices, each a behavior that works end to end. Each slice then runs `/ptah:plan` → `/ptah:implement` → `/ptah:review` → `/ptah:fix` → `/ptah:accept`, which commits it. Pass the slice number after the spec id (`/ptah:plan k3f9 2`), or leave it out to take the next ready slice. Once every slice is accepted, `/ptah:review` reviews the whole feature, and an `approved` final review means it's ready for a PR.

## Principles

- **Every step leaves a file.** The ticket, `SPEC.md`, `PLAN.md`, the code with `IMPLEMENTATION-SUMMARY.md`, and `REVIEW.md` are the audit trail, tied together by `LOGS.md`. Steps share nothing but the spec folder and the code, so you can read exactly what each one worked from.
- **One job per command.** `implement` doesn't review or open PRs; `review` never touches code.
- **You decide when to move on.** No command runs the next one; each ends by naming it.
- **Reviews start fresh.** The reviewer sees only the spec folder and the code, never the conversation that wrote it, so it can't inherit the reasons the code was written that way.
- **Fail loudly.** A command stops when something it needs is missing (the previous step's file, the ticket, the ticket server, a valid result from its agent) instead of guessing past it.
