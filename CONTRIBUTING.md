# GitHub conventions

Work at Final Phase is tracked as slices in Notion. Each slice has an Item ID such as `SPARK-41` or `ROGER-30`. GitHub mirrors that ID everywhere so you can follow one slice from plan to merge.

## Issues

Open one issue per slice.

- Title: `<ITEM-ID> short title`, for example `SPARK-41 Read-only API keys cannot write`.
- Body: the Notion plan link and the done-when line from the slice.
- Labels: one `lane:`, one `agent:`, and a `customer:` label when the work is for a customer.

## Branches

Name the branch `<agent>/<item-id>-slug`, all lowercase.

Example: `spark/spark-41-readonly-keys`.

`<agent>` is one of `spark`, `claude-code`, `codex`, `grok-build`, `cursor`.

## Pull requests

Start the title with the Item ID: `SPARK-41 Block writes from read-only keys`.

The body has these parts:

1. The Notion plan link.
2. What changed and why, in a few lines.
3. Proof: the check output, test result, or live check.
4. A screenshot, when anything visible changes.
5. `Fixes #N`, where N is the slice issue.

Add a `Co-authored-by` trailer for the human who asked for the work to each commit.

GitHub closes the issue when the PR merges.

## Who merges

Coding agents open pull requests. They never merge, deploy, or change environment variables or DNS.

A merge needs a passing `ship-pr prep` run on the exact head commit. Only Spark merges product engineering PRs.

## Labels

Each repo that is in active use has these labels. Ask Spark to add them to a new repo.

| Label | Use it for |
| --- | --- |
| `lane:<owner>` | The owner of the slice in Notion: `chief`, `spark`, `aspen`, `roger`, `louis`, `vera`, `gabe`, `routines`, `support`, `dr-eggbot`. |
| `agent:<agent>` | The agent doing the work: `agent:spark`, `agent:claude-code`, `agent:codex`, `agent:grok-build`, `agent:cursor`. |
| `customer:<slug>` | Work for one customer. Only in customer repos. |

Set one `lane:` and one `agent:` label on every issue and PR. Add `customer:` only where the label exists.
