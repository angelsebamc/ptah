# Delegated work

A dispatching skill is a thin dispatcher. The subagent's prompt is the spec folder path and the plugin root, nothing else, plus a `Slice:` line with the slice folder when the work is one slice of a sliced spec, per [`slices.md`](./slices.md). The reviewer also gets its axis and the base ref, and on a review without a Ptah spec it gets the branch and the ticket file, if any, in place of the folder. The subagent reads what it needs from disk, so the dispatcher never summarizes the conversation or explains anything on the user's behalf.

The **plugin root** is the absolute path of `../..`, resolved from the dispatching skill's directory. It is the only way the subagent learns where Ptah is installed.

Subagents can't talk to the user, so **Stop and ask** in [`RULES.md`](../RULES.md) becomes a loop:

1. Where the subagent would ask, it stops and returns result status `needs-input` with its questions, each tagged with the change-entry type its answer would be: `decision`, `deviation`, or `scope-change`.
2. The dispatcher logs a `/<command> paused` command entry, then asks the questions.
3. When an answer contradicts `SPEC.md` or `PLAN.md`, the dispatcher updates that file per **Artifact ownership** in `RULES.md`. Then, for every answer, it appends a change entry with `Trigger: user-request`, the tagged type, and `What:` the answer as a one-line decision.
4. The dispatcher re-dispatches with the same prompt. The subagent finds the answers in `LOGS.md`, where they belong anyway.

An answer the user can't give yet because it needs something outside Ptah, such as an approval, is logged with a `What:` starting `not-answered-yet:`. Keep asking the remaining questions, then hand off as paused instead of re-dispatching, with `Next:` naming what the user needs to do, then the command to re-run. On that re-run, before re-dispatching, ask again every question whose answer since the last `paused` entry is still only `not-answered-yet:`, and log the new answer: done by the user, plan changed, or still blocked.

## Handling the result

First check the subagent's result against every rule in [`the result format`](./result-format.md). Then act on its status:

- **`complete`:** write the artifact block verbatim to the work folder per **Slice state** in [`slices.md`](./slices.md) (the spec folder on a flat spec), then append `/<command> completed` per [`the logs format`](./logs-format.md), copying the result's fields.
- **`needs-input`:** run the loop above, copying the result's fields verbatim into the `/<command> paused` entry. Ask the `### Questions` in the order returned. Reword one if it reads better, but every question reaches the user whole: never answer, soften, or drop one. Each names who does each thing: you (the user) or the agent.
- **`error`, or a malformed result:** write no artifact, append `/<command> failed`, and hand off as failed. If the result was malformed, offer to show the raw response.

Then hand off per the result format.
