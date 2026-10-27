# Project config

`.ptah/ptah.yml`, relative to the project root. `/ptah:init` sets it up. The file and every key in it are optional. A missing key uses its default.

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

| Key | Default | Written by | Read by | Meaning |
|-----|---------|------------|---------|---------|
| `specs.next_id` | `1` | `/ptah:spec` | `/ptah:spec` | Number for the next spec without a ticket. Only moves forward; never edit it by hand to reuse a number. |
| `commands.fix.mode` | `plan` | `/ptah:init` | `/ptah:fix` | Default fix mode, one of the fix modes in [`vocabulary`](./vocabulary.md). A flag overrides it for one run. |
| `commands.fix.include_minor` | `false` | `/ptah:init` | `/ptah:fix` | Whether `/ptah:fix` also fixes minor findings by default. |
| `context_sources.<key>` | — | `/ptah:init` | `/ptah:spec` | MCP server to use for `/ptah:spec <key>=<ticket-id>`. Unset, `/ptah:spec` looks for a server named after `<key>`. |
