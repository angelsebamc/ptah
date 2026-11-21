---
name: grill
description: 'Grills the user in rounds of questions until you share a design concept of a plan, idea, or decision. Writes nothing. Use when the user asks to be grilled or to stress-test their thinking.'
argument-hint: '[<topic>]'
---

# /grill

Grill the user relentlessly until the two of you share a **design concept**: one understanding of what's being built or decided. A gap you fill silently looks exactly like a choice, so it surfaces late, at review or in the built feature. Ask instead.

The topic is `$ARGUMENTS`. When that's empty, it's what the conversation is about; when the conversation hasn't named one either, ask what to grill.

## Design tree

The open decisions form a **design tree**: each decision branches into the decisions that hang off it, and each flow into its empty states, failures and edge cases. Ask only what changes the design concept.

Facts are yours to find, decisions are the user's: read the files yourself, or dispatch an Explore subagent for a wide search. Before asking how something should behave, find how the closest existing equivalent does it, and recommend that, cited as `<file>:<line>`, or say why not. Flag a recommendation that rests only on how things are done now, so the user knows to bring their own judgement. A lookup still running holds back only the questions that depend on it; ask the rest now.

## Rounds

Work the tree in rounds. The **frontier** is every decision whose prerequisites are settled: the questions you can ask now without guessing at answers you haven't heard. Ask the whole frontier at once, then wait for the reply. Number the questions so the user can answer by number:

```
**1. <short title>**
<the question, with options when there are a few clear ones>
Recommended: <your answer, and why in a few words>
```

Word each question so "yes" accepts the recommendation, and separate rounds with `---`. Each reply moves the frontier: recompute it and ask the next round.

## Done

The grill is done when the frontier is empty: every branch visited and nothing silently assumed. Then summarize the design concept and wait until the user confirms it, folding in any correction.
