# Project config

The project config is `.ptah/ptah.yml` at the project root, created by `/ptah:init`:

```yaml
commands:
  implement:
    review: false
  fix:
    mode: plan

tickets:
  server: claude_ai_Linear
```

## Keys

| Key | Required | Written by | Read by | Meaning |
|-----|----------|------------|---------|---------|
| `commands.fix.mode` | yes | `/ptah:init` | `/ptah:fix` | Fix mode, one of the fix modes in [`vocabulary`](./vocabulary.md). A flag overrides it for one run. |
| `commands.implement.review` | no | `/ptah:init` | `/ptah:implement` | Whether `/ptah:implement` runs `/ptah:review` once the implementation is complete. Unset means `false`. |
| `tickets.server` | no | `/ptah:init` | `/ptah:spec`, `/ptah:review` | Full name of the MCP server that `/ptah:spec <ticket-id>` and `/ptah:review` without a Ptah spec fetch tickets from. Unset, `/ptah:spec <ticket-id>` stops and asks for `/ptah:init`, and `/ptah:review` handles it per its Step 3. |

A command changes only the keys it writes and leaves every other key exactly as it was.

## Required keys

A command that checks the config reads `.ptah/ptah.yml` and stops if the file is missing, isn't valid YAML, or lacks a required key:

> "Ptah isn't set up for this project. Run `/ptah:init` first."

It also stops if `commands.fix.mode` isn't one of the fix modes in [`vocabulary`](./vocabulary.md), or `commands.implement.review` is set to anything but `true` or `false`:

> "Invalid `<key>` value `<value>` in `.ptah/ptah.yml`. Run `/ptah:init` to fix it."
