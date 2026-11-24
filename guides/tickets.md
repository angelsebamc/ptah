# Tickets

How a command gets a ticket from the project's ticket server.

## Fetching a ticket

`<server>` is `tickets.server` in `.ptah/ptah.yml`. Stop with the message that fits when:

- it's unset: "No ticket server is set for this project. Run `/ptah:init` to choose one."
- no MCP server named `<server>` is available in this session, listing the ones that are: "MCP server `<server>` isn't available. Available servers: <list>. Install or enable it, or run `/ptah:init` to choose another."
- a folder matching `.ptah/specs/<ticket-id>-*` (case-insensitive) already exists, since a ticket gets exactly one spec folder: "Ticket `<ticket-id>` already has a spec at `.ptah/specs/<folder>/`. Run `/ptah:resume <ticket-id>`." A missing `.ptah/specs/` is no match; if the check itself fails, stop and show its error.

Then fetch `<ticket-id>` with `<server>`'s MCP tools. If it doesn't exist, stop: "Ticket `<ticket-id>` wasn't found on `<server>`."
