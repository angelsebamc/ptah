# Project config

`.ptah/ptah.yml`, relative to the project root. `/ptah:init` creates it.

```yaml
specs:
  next_id: 4

commands:
  fix:
    mode: plan
    include_minor: false

context_sources:
  linear: claude_ai_Linear
```

---

## Keys

| Key | Required | Written by | Read by | Meaning |
|-----|----------|------------|---------|---------|
| `commands.fix.mode` | yes | `/ptah:init` | `/ptah:fix` | Fix mode, one of the fix modes in [`vocabulary`](./vocabulary.md). A flag overrides it for one run. |
| `commands.fix.include_minor` | yes | `/ptah:init` | `/ptah:fix` | Whether `/ptah:fix` also fixes minor findings. |
| `specs.next_id` | no — starts at `1` | `/ptah:spec` | `/ptah:spec` | Number for the next spec without a ticket. Only moves forward; never edit it by hand to reuse a number. |
| `context_sources.<key>` | no | `/ptah:init` | `/ptah:spec` | MCP server to use for `/ptah:spec <key>=<ticket-id>`. Unset, `/ptah:spec` looks for a server named after `<key>`. |

A command changes only the keys it writes and leaves every other key exactly as it was.

---

## Required keys

A command that checks the config reads `.ptah/ptah.yml` and stops if the file is missing, isn't valid YAML, or lacks a required key:

> "Ptah isn't set up for this project. Run `/ptah:init` first."

If `commands.fix.mode` is set to anything other than a fix mode in [`vocabulary`](./vocabulary.md), or `commands.fix.include_minor` isn't `true` or `false`, stop:

> "Invalid `<key>` value `<value>` in `.ptah/ptah.yml`. Run `/ptah:init` to fix it."
