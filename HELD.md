# Held harness changes

While a project measures whether its own process changes work, the reviewer is held steady:
the review skills change only to fix something broken, and proposed changes are queued here
and made together when the window ends. A reviewer that changes while it measures makes
every comparison unreliable (the audit of October 4 found 11 harness versions in 5 days,
some stricter and some more lenient).

## Queue

Nothing is held. Add a row when a measurement window starts and a change is proposed during
it.

| Proposed | Change | Source |
|---|---|---|

## Released

The window that began at `2026.10.04.3` ended after ten reviewed PRs in
serverless-ai-scheduling. Everything queued during it shipped in `2026.10.06`; the designs
are in the commits "Release 1/n" to "Release 5/n", and the changes that can move a count are
recorded with targets in `skills/improve-agent-process/references/harness-changes.md`.

| Proposed | Change | Shipped as |
|---|---|---|
| 2026-10-06 | An enforced exchange contract between orchestrators, subagents and scripts | `references/contracts.md` and `scripts/validate.sh` in `review-agent-pr` and `review-agent-issue`; script-computed counts; `findings.json`; harness version in `progress.txt`; `apply-readiness.sh` (H1, H2) |
| 2026-10-06 | Readiness fixes from the readiness investigation, with `Decision r<k>/ALL: accept` limited to what is safe to accept in bulk | Readiness format and briefs; `apply-readiness.sh` (H2, H3) |
| 2026-10-06 | A generality check for every harness change | README, "Contributing: the generality check"; recorded in each release commit |
| 2026-10-06 | Three rewordings for generality | `address-pr-review` step 3 (recorded evidence a test can fail); readiness format (manual verification routed to wherever the project records it); decisions wording re-checked, unchanged |
| 2026-10-04 | Reviewer-quality signals in each batch | `improve-agent-process` step 3; `get-process-log.sh` reviewer signals |
| 2026-10-04 | Cost per review in the run metadata | `cost=` lines in `progress.txt`, totalled on the process data line (H6) |
| 2026-10-04 | Harness changes batched and measured like project changes | `references/harness-changes.md`, measured in `improve-agent-process` step 2 |
| 2026-10-04 | An intake for process incidents outside a PR | `improve-agent-process`, "Log an incident" |
| 2026-10-04 | Escaped questions | Readiness state on the process data line and in `findings.json`; counted in `improve-agent-process` step 2 |
| 2026-10-04 | Spec drift in the PR manifest | `spec-moves.sh` (H4) |
| 2026-10-04 | A "spec moved" marker, not counted as an agent mistake | "Spec moved" field, `spec-moved` failure class (H4) |
| 2026-10-06 | Related upcoming issues in PR reviews, with the four guardrails | `related-issues.sh`; the verifier's step 10; `post-deferral.sh`; readiness reads deferral notes; unpicked deferrals counted (H5) |
