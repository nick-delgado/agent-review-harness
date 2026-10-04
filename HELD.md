# Held harness changes

From harness version `2026.10.04.3` the reviewer is held steady while the
serverless-ai-scheduling project measures whether its own process changes work: for the
next 8 to 10 reviewed PRs there, the review skills change only to fix something broken.
A reviewer that changes while it measures makes every comparison unreliable (the audit of
October 4 found 11 harness versions in 5 days, some stricter and some more lenient).

Changes proposed in the meantime are listed here and made together after the window.

| Proposed | Change | Source |
|---|---|---|
| 2026-10-04 | Reviewer-quality signals in each batch: findings the verifier rejected, owner decisions that overrode a recommendation, findings the fixing agent disputed, defects introduced by a suggested fix, and findings a later round found in code an earlier round passed | Loop audit, recommendation 4 |
| 2026-10-04 | Cost per review (subagent tokens and time) recorded in the run metadata | Loop audit |
| 2026-10-04 | Batch harness changes like project changes, with an ID and a target, and measure them the same way | Loop audit |
| 2026-10-04 | An intake for process incidents that happen outside a PR (for example a scratch folder that held secrets) | Loop audit |
| 2026-10-04 | review-agent-pr: count "escaped questions", spec guesses a PR review still finds on issues a readiness review marked ready, so improve-agent-process can measure what readiness misses | review-agent-issue design |
