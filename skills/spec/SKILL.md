---
name: spec
description: 'Starts a new Ptah feature spec: creates the spec folder (<TICKET-ID>-<slug> from a ticket, <repo>-<code>-<slug> otherwise) and fills SPEC.md by grilling the developer in rounds of questions, looking facts up in the codebase instead of asking, optionally starting from a ticket fetched through the project''s ticket server'
argument-hint: '[<ticket-id> | <ticket-url>]'
disable-model-invocation: true
---

# /spec

Grill the developer until every decision the spec needs is settled, then write `SPEC.md` in a new spec folder. A ticket, when given, is the starting point.

`RULES.md` is `../../RULES.md`. Read it before Step 1 unless its full text is already in your context.

## Step 1 — Parse command arguments

Raw arguments: `$ARGUMENTS`, trimmed.

- **Empty** → a spec without a ticket.
- **One token shaped like a ticket id**, per **Ticket ids** in `../../guides/spec-identifiers.md` → a ticket spec, with `<ticket-id>` = the token.
- **One `http://` or `https://` URL** whose path segments and query-parameter values hold exactly one id shaped like a ticket id (case-insensitive) → a ticket spec, with `<ticket-id>` = that id. E.g. `https://linear.app/some-org/issue/PROJ-41/some-title` gives `PROJ-41`; `https://some-org.atlassian.net/jira/software/projects/PROJ/boards/12?selectedIssue=PROJ-1234` gives `PROJ-1234`.
- **Anything else** → show the examples below and stop.

`<ticket-id>` keeps the casing it was given in.

Examples:
- `/ptah:spec`: plain feature, no external ticket. The name comes from your answers
- `/ptah:spec PROJ-1234`: pulls context from ticket PROJ-1234 through the project's ticket server
- `/ptah:spec https://some-org.atlassian.net/browse/PROJ-1234`: the same, with the ticket id taken from the URL

---

## Step 2 — Check the config and fetch the ticket

Check the config per **Required keys** in `../../guides/config.md`.

Without a ticket, get `<repo>` now, per `../../guides/spec-identifiers.md`, so a missing git repository stops the command before the grill instead of after it.

With a ticket, `<server>` is `tickets.server` in `.ptah/ptah.yml`. Stop with the message that fits when:

- it's unset: "No ticket server is set for this project. Run `/ptah:init` to choose one."
- no MCP server named `<server>` is available in this session, listing the ones that are: "MCP server `<server>` isn't available. Available servers: <list>. Install or enable it, or run `/ptah:init` to choose another."
- a folder matching `.ptah/specs/<ticket-id>-*` (case-insensitive) already exists, since a ticket gets exactly one spec folder: "Ticket `<ticket-id>` already has a spec at `.ptah/specs/<folder>/`. Run `/ptah:resume <ticket-id>`." A missing `.ptah/specs/` is no match; if the check itself fails, stop and show its error.

Then fetch `<ticket-id>` with `<server>`'s MCP tools. If it doesn't exist, stop: "Ticket `<ticket-id>` wasn't found on `<server>`."

Tell the user which ticket you loaded (id and title) and list what it settles: what the feature is, why it matters, and any acceptance criteria or flows it states. Say you'll treat those as decided and ask only about what it leaves open.

---

## Step 3 — Grill the developer

Grill the developer relentlessly on what the feature must do. How to build it belongs to `/ptah:plan`.

### What the spec holds

The grill fills this template. Write one user story per actor and need, and end each acceptance criterion with the id of the story it proves. The `Source:` line is for a ticket spec only.

```markdown
# SPEC — <feature-name>

> **Source:** [<ticket-id>](<ticket-url>) — <ticket-title>

## Description
<the feature in one sentence>

## Problem
<the problem it solves, from the user's perspective>

## User stories
- US1: As a <actor>, I want <need>, so that <benefit>.

## Use cases
<the main flow step by step (what the actor does, what the app does, the end result), then each alternate and error flow with the condition that triggers it>

## Acceptance criteria
- <a testable condition> (US1)

## References
<the files in refs/ and what each shows, or "none">

## Out of scope
<what the feature deliberately leaves out>
```

### Design tree

The open decisions form a **design tree**. Its branches reach every section of the template plus the existing features, data and APIs the feature touches, and each flow branches into its empty states, failures and edge cases. Ask only what changes the spec. On a ticket spec, what the ticket settles is decided: ask only about what it leaves open or gets wrong against the code.

Facts are yours to find, decisions are the user's. Look facts up per **Stop and ask** in `RULES.md`, reading the files yourself or dispatching an Explore subagent for a wide search. A lookup still running holds back only the questions that depend on it; ask the rest now.

### Rounds

Work the tree in rounds. The **frontier** is every decision whose prerequisites are settled: error flows wait on the main flow, criteria on the stories. Ask the whole frontier at once, then wait for the reply. Number the questions so the user can answer by number:

```
**1. <short title>**
<the question, with options when there are a few clear ones>
Recommended: <your answer, and why in a few words>
```

Word each question so "yes" accepts the recommendation, and separate rounds with `---`. Each reply moves the frontier: recompute it and ask the next round.

### Done

The grill is done when the frontier is empty: every branch visited, nothing in the spec silently assumed, every story proved by at least one acceptance criterion and every criterion proving a story. Ask about any gap as another round. Then show the user a summary of the spec and wait until they confirm it, folding in any correction.

---

## Step 4 — Create the spec folder

Name the folder per `../../guides/spec-identifiers.md`: `<ticket-id>-<kebab>` for a ticket spec, `<repo>-<code>-<kebab>` otherwise.

**`<code>`** (no ticket only) always comes from the shell, never from you. Run, in a POSIX shell:

```sh
LC_ALL=C tr -dc 'a-z0-9' </dev/urandom | head -c 4
```

or in PowerShell:

```powershell
-join (1..4 | ForEach-Object { 'abcdefghijklmnopqrstuvwxyz0123456789'.ToCharArray() | Get-Random })
```

If a folder in `.ptah/specs/` already starts with `<repo>-<code>-`, run it again.

**`<feature-name>`** is the ticket's title. Without a ticket, infer it from the Description and Problem the grill settled, without asking: a short phrase naming what the feature does, e.g. `user login`.

**`<kebab>`** is `<feature-name>` in kebab-case, per that guide. If it's longer than 50 characters, cut it at the last `-` before the 50th character.

Create `.ptah/specs/<folder>/` holding `LOGS.md`, `SPEC.md`, and an empty `refs/`.

---

## Step 5 — Write, log, and hand off

Write the spec the user confirmed to `.ptah/specs/<folder>/SPEC.md`, in the template from Step 3.

Append a `/spec completed` entry to `.ptah/specs/<folder>/LOGS.md` per `../../guides/logs-format.md`.

Hand off per `../../guides/result-format.md`, naming the spec by its display id `<id>` per **Displaying an identifier** in `../../guides/spec-identifiers.md`. Without a ticket, include the inferred name among the key facts, e.g. `Feature: user login`.
