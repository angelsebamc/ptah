# Delegated work

- **The prompt is the folder path, nothing else.** The subagent reads `SPEC.md`, `PLAN.md`, `LOGS.md`, `refs/`. The dispatcher never summarizes the conversation or explains anything on the user's behalf.

Subagents can't talk to the user, so **Stop and ask** in [`RULES.md`](../RULES.md) becomes a loop:

1. The subagent hits something it would normally ask about. It stops and returns its questions, each tagged with the change-entry type the answer would be (`decision`, `deviation`, `scope-change`) — result status `needs-input`.
2. The dispatcher logs a `/<command> paused` command entry, then asks the questions one at a time.
3. After each answer, the dispatcher appends a change entry recording it (`Trigger: user-request`, the tagged type, `What:` the answer as a one-line decision).
4. The dispatcher re-dispatches with the same prompt — just the folder path. The subagent finds the answers in `LOGS.md`, where they belong anyway.

## Handling the result

First check the subagent's result against every rule in [`the result format`](./result-format.md).

- **`complete`** — write the artifact block verbatim to the spec folder, then append `/<command> completed` per [`the logs format`](./logs-format.md), copying the result's fields and adding `Next step:`.
- **`needs-input`** — run the loop above: append `/<command> paused` copying the result's fields verbatim, ask the `### Questions` one at a time in the order returned (reword if it reads better, but never answer, soften, or drop one), log each answer, then re-dispatch.
- **`error`, or a malformed result** — write no artifact, append `/<command> failed`, and hand off as failed. If the result was malformed, offer to show the raw response.

Then hand off per the result format.
