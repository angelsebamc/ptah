---
name: pull
description: 'Creates a Ptah spec folder from a ticket that already holds a spec, such as one /ptah:spec filed, writing its description to SPEC.md without a grill.'
argument-hint: '<ticket-id> | <ticket-url>'
disable-model-invocation: true
---

# /pull

Create the spec folder for a ticket whose description is already the spec. Copy it; settling the spec was `/ptah:spec`'s job.

`RULES.md` is `../../RULES.md`. Read it before Step 1 unless its full text is already in your context.

## Step 1 — Parse command arguments

Raw arguments: `$ARGUMENTS`, trimmed. `<ticket-id>` is the argument when it's one token shaped like a ticket id, per **Ticket ids** in `../../guides/spec-identifiers.md`, or the id from one URL per **A ticket id from a URL** in that guide.

Anything else, an empty argument included, shows the examples below and stops:

- `/ptah:pull PROJ-1234`: creates the spec folder for ticket PROJ-1234
- `/ptah:pull https://some-org.atlassian.net/browse/PROJ-1234`: the same, with the ticket id taken from the URL

---

## Step 2 — Fetch the ticket

Check the config per **Required keys** in `../../guides/config.md`, then fetch `<ticket-id>` per **Fetching a ticket** in `../../guides/tickets.md`.

---

## Step 3 — Create the spec folder

`<feature-name>` is the ticket's title. Name the folder `<ticket-id>-<slug>` per `../../guides/spec-identifiers.md`, and create `.ptah/specs/<folder>/` holding `LOGS.md`, `SPEC.md`, and an empty `refs/`.

Write `SPEC.md` as:

```markdown
# SPEC — <feature-name>

> **Source:** [<ticket-id>](<ticket-url>) — <ticket-title>

<the ticket's description, verbatim>
```

The step is done when everything below the `Source:` line matches the ticket's description word for word.

---

## Step 4 — Log and hand off

Append a `/pull completed` entry to `.ptah/specs/<folder>/LOGS.md` per `../../guides/logs-format.md`.

Hand off per `../../guides/result-format.md`, naming the spec by its display id `<id>` per **Displaying an identifier** in `../../guides/spec-identifiers.md`.
