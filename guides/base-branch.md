# Base branch

The **base** is the branch the current branch was cut from: `main` in one repo, `develop` or a `release/*` branch in another.

## Resolving the base

If `--base <ref>` was given, use it. It must resolve to a commit; if it doesn't, stop: "`<ref>` isn't a branch, tag, or commit." Source: `from --base`.

Otherwise, look at the oldest entry in the current branch's reflog. If it says the branch was created from another branch that still exists, locally or on `origin`, that's the base. Source: `from the reflog`. An entry that says `Created from HEAD` or from a commit id names no branch, and neither does a detached `HEAD`, which has no reflog of its own.

Otherwise, take the nearest branch: of the local and `origin/` branches, the one whose merge-base with `HEAD` is the fewest commits behind `HEAD`. A local branch and its `origin/` copy are one candidate, named by the local one. Leave out the current branch and its remote copy, `origin/HEAD`, branches with unrelated histories, and any branch cut from this one (it holds `HEAD` plus newer commits). Source: `nearest branch`.

If two candidates tie, or none qualify, ask, listing the tied ones if any:

> "Which branch was `<branch>` cut from? (e.g. `main`, `develop`)"

Check the reply as you would `--base`. Source: `from you`.

Show the base and its source: "Compared against `<base>` (<source>)."

## The changes

The changes run from the merge-base of `HEAD` and the base to the working tree: committed and uncommitted edits together, plus untracked files that aren't ignored. Read each changed file's diff against the merge-base, and an untracked file whole.
