# Spec identifiers

Ptah names every spec folder one of two ways:

- **From a ticket:** `<TICKET-ID>-<slug>`, e.g. `PROJ-45-add-csv-export`. The ticket id keeps its original casing and `<slug>` comes from the ticket title. Ticket specs take no code.
- **Without a ticket:** `<repo>-<code>-<slug>`, e.g. `some-web-k3f9-user-login`. `<code>` is 4 random lowercase letters and digits that `/ptah:spec` generates, and `<slug>` comes from the name it infers from the spec conversation.

**Kebab-case** means lowercase, with spaces and underscores turned into `-` and other punctuation removed.

`<slug>` is that name in kebab-case. If it's longer than 50 characters, cut it at the last `-` before the 50th character.

`<repo>` is the name of the project's git root folder (the last path segment of `git rev-parse --show-toplevel`) in kebab-case. Outside a git repository, stop:

> "Ptah names specs after the git repository. Run this command inside one."

## Ticket ids

A token is **shaped like a ticket id** when it is a letter, then letters or digits, a `-`, then digits, e.g. `PROJ-1234`.

**A ticket id from a URL.** An `http://` or `https://` URL gives a ticket id when its path segments and query-parameter values hold exactly one id shaped like a ticket id (case-insensitive). E.g. `https://linear.app/some-org/issue/PROJ-41/some-title` gives `PROJ-41`; `https://some-org.atlassian.net/jira/software/projects/PROJ/boards/12?selectedIssue=PROJ-1234` gives `PROJ-1234`.

**A ticket id from the branch.** Take the part of `git branch --show-current` after the last `/`. If, ignoring case, it is shaped like a ticket id or starts with one followed by `-`, that id uppercased is the branch's ticket id: `user/proj-45-csv-export` gives `PROJ-45`, and `csv-export` gives none.

## Resolving an identifier

A `<spec-id>` may be a bare code (`k3f9`), a prefixed code (`some-web-k3f9`), a ticket id (`PROJ-45`), or the full folder name, and matching ignores case: `PROJ-45` and `proj-45` are the same spec. Resolve it in this order:

1. With no `<spec-id>`, get one per **When the identifier is omitted**.
2. A folder in `.ptah/specs/` with exactly that name is the spec.
3. Otherwise glob `.ptah/specs/<repo>-<spec-id>-*` if it has no `-`, or `.ptah/specs/<spec-id>-*` if it has one.
4. One match is the spec. With several, stop, list them, and ask for the full folder name. With none, stop: "No spec found for `<spec-id>`."
5. Offer the spec's branch per **Switching to the spec's branch**. Never skip this step.

Commands call the resolved folder `<feature-name>`.

## When the identifier is omitted

Take the spec from the first of these sources that gives one:

1. **The git branch.** Take the part of `git branch --show-current` after the last `/`. It names a spec when, ignoring case, it is that spec's id (`<repo>-<code>` for a spec without a ticket, the ticket id for a ticket spec) or starts with that id followed by `-`. So `user/PROJ-45-csv-export` names `PROJ-45-add-csv-export`, and `PROJ-4-fix` doesn't. If it names more than one spec, stop, list them, and ask for the full folder name.
2. **This session's last hand-off.** Use the `<id>` from the first line of the most recent Ptah hand-off in this conversation, `/<command> <id> <status>` (e.g. `/review PROJ-45 completed`). Skip a hand-off that starts `/review branch`: it names no spec.
3. **The user picks.** If `.ptah/specs/` has no specs, stop: "No specs yet. Run `/ptah:spec` to start one." Otherwise ask, listing every spec by its display id and the rest of its folder name, specs without a ticket first, then wait for the reply and use it as `<spec-id>`:
   > "Which spec? Reply with its id.
   >
   > These specs are available:
   > - k3f9 user-login
   > - PROJ-45 add-csv-export"

These three sources are the only ones: never guess from folder names or `LOGS.md` timestamps. When the branch or the hand-off gave the spec, tell the user before anything else which spec you're using and where it came from, naming the branch or saying it came from this session.

## Switching to the spec's branch

Once a spec is resolved, whether from the command's argument or a source in **When the identifier is omitted**, skip this if the current branch already names it by the rule in **The git branch**. Otherwise look for local branches that name it by the same rule (`git branch --format='%(refname:short)'`):

- **One:** ask whether to switch to it, naming the spec and the branch.
- **More than one:** list them and ask which one to switch to, if any.
- **None:** offer to create one per **Creating the spec's branch**.

When the user declines, stay on the current branch. Before switching, check `git status --porcelain`. With uncommitted changes, don't switch; stop:

> "You have uncommitted changes on `<current-branch>`. Commit or stash them, then run `/ptah:<command> <id>` again."

Otherwise run `git switch <branch>` and go on with the command.

## Creating the spec's branch

If `git status --porcelain` shows uncommitted changes, don't offer: stay on the current branch. Otherwise:

1. Get the base with `git symbolic-ref --short refs/remotes/origin/HEAD`.
2. Ask whether to create `<feature-name>` from that base, telling the user they can reply with another name or base instead. If step 1 failed there's no default, so ask which existing branch to base it on (e.g. `develop`), or whether to skip it.
3. A name the user gives must start with the spec's id by the rule in **The git branch**: `user/PROJ-45-csv`, not `csv-export`. If it doesn't, say so and ask again.
4. `<base-branch>` is the base without a leading `origin/`. Run `git fetch origin <base-branch>`. If it fails, show its error and ask whether to create the branch from the last fetched `origin/<base-branch>`, warning that it may be behind. On no, stop.
5. Run `git switch --no-track -c <name> origin/<base-branch>` and go on with the command. If the switch fails, stop and show its error.

## Displaying an identifier

Output shown to the user (hand-offs and `/ptah:resume`'s summary) names a spec only by its **display id**, written `<id>`:

- A spec without a ticket, whose folder starts with `<repo>-<code>-`, shows only its code, e.g. `/ptah:plan k3f9`.
- A ticket spec shows its ticket id as written in the folder name, everything up to and including the first run of digits, e.g. `/ptah:plan PROJ-45`.

File paths the user is meant to open are the exception: they use the full folder name.
