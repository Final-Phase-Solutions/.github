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

Put the same attribution trailers at the end of the PR body as on the commits, so a squash merge keeps them. See [Commit attribution](#commit-attribution).

GitHub closes the issue when the PR merges.

## Commit attribution

Every commit an agent makes ends with exactly one agent line and one model line:

```text
Co-authored-by: <agent line>
Agent-Model: <model name and version>
```

The agent line is one of these, spelled exactly:

| Agent | Line |
| --- | --- |
| Spark | `Co-authored-by: Spark <spark@final-phase.com>` |
| Claude Code | `Co-authored-by: Claude Code <noreply@anthropic.com>` |
| Codex | `Co-authored-by: Codex <noreply@openai.com>` |
| Grok Build | `Co-authored-by: Grok Build <noreply@x.ai>` |

Keep the model version out of the name. Do not add `Co-authored-by: Gabe Russo` to agent commits.

A commit Gabe writes by hand ends with `Human: Gabe` and no agent line.

Dependabot commits and merge commits need no trailer.

Three things enforce this, all from one rule file, [.githooks/commit-attribution.sh](.githooks/commit-attribution.sh):

1. A `commit-msg` hook in each repo's `.githooks/` folder. `npm install` turns it on through the `prepare` script, which runs `git config core.hooksPath .githooks`. In a repo with no `package.json`, run that command yourself.
2. The [commit-attribution workflow](.github/workflows/commit-attribution.yml). It fails a PR when a commit or the PR body has no allowed trailer, or when the repo's copy of the rule file differs from this one. Each repo calls it from `.github/workflows/attribution.yml`.
3. `ship-pr prep`, which refuses a branch whose commits fail the rule and writes the trailers into the PR body and the squash message.

To change the rule, edit the rule file here, run `sh scripts/test-commit-attribution.sh`, then copy the file into each repo's `.githooks/`.

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

## Agent routing

See [AGENT-ROUTING.md](AGENT-ROUTING.md) for which agent takes a slice and the brief template every T3 brief uses.
