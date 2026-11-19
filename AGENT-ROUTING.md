# Agent routing and T3 brief template

This page says which coding agent takes a slice and what every brief to that agent must contain. It builds on [CONTRIBUTING.md](CONTRIBUTING.md).

Spark coordinates the agents through T3 Code, which runs one thread and one git worktree per task. Agents open pull requests. Spark reviews the evidence and merges.

The agents are Claude Code, Codex and Grok Build.

Status: these are default rules, not measured results. No benchmark backs the routing table. Revise it when real outcomes say otherwise.

## Routing rule

1. **One agent per slice by default.** One slice, one branch, one agent. Do not run several agents on the same slice.
2. **Route by task type.**

   | Task type | Default agent |
   | --- | --- |
   | UI-heavy work, anything that needs a screenshot | Claude Code |
   | Long refactors and multi-file changes | Codex |
   | Tight bug fixes and test-only changes | Grok Build |
   | Anything else | Claude Code |

3. **Tie-break.** If a slice fits two rows, pick the agent that has no other open branch in the same repo. If both are equally free, use the one in the "Anything else" row.
4. **Retry once on a different agent.** If an attempt fails (`check:local` still fails after the agent's own fixes, or Spark rejects the evidence twice), open a new branch for a different agent and start from the original brief. Put the failure reason in the new brief. Do not retry a third time. Escalate to the slice owner.
5. **Arena only for real design forks.** Use the arena skill, which runs several candidates on one task, only when the slice has an open design question that evidence can settle. Do not use it for routine slices.

Record the agent in the branch name and the `agent:<agent>` label from [CONTRIBUTING.md](CONTRIBUTING.md).

## Brief template

Every T3 brief spells out all of these. Fill in each field. Do not drop a field.

```text
Goal: <the goal in the requester's words>. Item ID: <ITEM-ID>.

Repo and branch: <org/repo>, branch <agent>/<item-id>-slug, created from origin/main
in its own T3 worktree. <agent> is claude-code, codex or grok-build.

Rules: follow the "Rules and what enforces them" table in this repo's AGENTS.md.
<paste the table rows that apply to this slice>
Do not add prose rules. If you hit a new class of mistake, say so in the PR.

Done when:
- `npm run check:local` passes at your head commit.
- Evidence is attached for any UI change: screenshots at 390 px and 1280 px wide.
- The PR follows the format in CONTRIBUTING.md and starts with the Item ID.

Do not: merge, deploy, change DNS or environment variables, write to Notion,
or send messages to anyone.

Load first: /pstack poteto-mode, spark-talk-principles and no-comments.

Hand-off: open a pull request. Spark reviews the evidence and merges.
```

## Why the brief is fixed

- poteto-mode, spark-talk-principles and no-comments go into every brief, so each agent starts with the same working rules.
- The rule table lives in each repo's AGENTS.md, so agents on any machine can read it.
- The do-nots match the "Who merges" section of [CONTRIBUTING.md](CONTRIBUTING.md).
