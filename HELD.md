# Held harness changes

From harness version `2026.10.04.3` the reviewer is held steady while the
serverless-ai-scheduling project measures whether its own process changes work: for the
next 8 to 10 reviewed PRs there, the review skills change only to fix something broken.
A reviewer that changes while it measures makes every comparison unreliable (the audit of
October 4 found 11 harness versions in 5 days, some stricter and some more lenient).

Changes proposed in the meantime are listed here and made together after the window.

| Proposed | Change | Source |
|---|---|---|
| 2026-10-06 | **First in the release.** An explicit, enforced exchange contract between the orchestrators, their subagents and the scripts (see "Exchange contract" below) | Owner request |
| 2026-10-04 | Reviewer-quality signals in each batch: findings the verifier rejected, owner decisions that overrode a recommendation, findings the fixing agent disputed, defects introduced by a suggested fix, and findings a later round found in code an earlier round passed | Loop audit, recommendation 4 |
| 2026-10-04 | Cost per review (subagent tokens and time) recorded in the run metadata | Loop audit |
| 2026-10-04 | Batch harness changes like project changes, with an ID and a target, and measure them the same way | Loop audit |
| 2026-10-04 | An intake for process incidents that happen outside a PR (for example a scratch folder that held secrets) | Loop audit |
| 2026-10-04 | review-agent-pr: count "escaped questions", spec guesses a PR review still finds on issues a readiness review marked ready, so improve-agent-process can measure what readiness misses | review-agent-issue design |
| 2026-10-04 | review-agent-pr: list in the manifest the PRD and ADR changes on the base branch since the issue's readiness review and since the PR branched, so reviewers see when the spec moved under the work | Spec-drift design |
| 2026-10-04 | review-agent-pr: a "spec moved" marker for findings caused by a spec change after work began: a question for the owner, not a spec deviation, and not counted as an agent mistake in measurements | Spec-drift design |
| 2026-10-06 | Related upcoming issues in PR reviews (see "Related upcoming issues" below) | Owner request |

## Related upcoming issues

Design agreed on 2026-10-06, to build when the measurement window ends.

**Goal.** When the verifier settles suggested fixes and options (step 10), it knows which
open issues relate to the PR, so it can offer deferring a fix to an upcoming issue that
will cover it anyway, and avoid suggesting fixes that pre-empt or contradict an upcoming
issue's settled readiness answers.

**Pieces.**

1. **A script, `related-issues.sh`,** run by the orchestrator, whose output goes into the
   manifest as facts: open issues whose owned paths or description name files in the PR's
   diff, issues linked from the PR's issue, and each one's acceptance criteria, owned paths
   and "Decisions and clarifications" section. The orchestrator adds nothing of its own
   (isolation rules).
2. **The verifier's step 10:**
   - a **defer to #N** option on a finding, under the guardrails below;
   - a **consistency check:** a suggested fix that would pre-empt or contradict an upcoming
     issue's settled answers is flagged, and the option consistent with them is
     recommended.
3. **address-pr-review:** when the owner chooses to defer, post a short note on the target
   issue (with a marker, naming the PR, the finding and what was deferred), the same way it
   files a follow-up issue when the owner chooses that.
4. **review-agent-issue:** the sibling check and refresh mode also read those deferral notes,
   so the issue's readiness review and its coding agent see what was deferred to it.
5. **improve-agent-process:** counts deferrals that were never picked up by the target
   issue's PR.

**Guardrails.**

1. **Defer only on evidence:** offered only when the upcoming issue's acceptance criteria or
   owned paths actually cover the fix, quoted. "Looks related" is not enough.
2. **Never for serious problems:** no deferral for blockers, major behaviour defects, or
   where deferring would ship the PR wrong on its own terms (a broken behaviour, a false
   claim).
3. **The owner decides:** deferral is an option on a "needs owner decision" finding, with a
   recommendation; the default stays "fix now". The verifier never defers on its own.
4. **Recorded where it lands:** a chosen deferral is noted on the target issue (piece 3), so
   it cannot become an untracked follow-up.

## Exchange contract

Design agreed on 2026-10-06. Build it first in the post-window release, since the other
held items add more hand-offs between orchestrators, subagents and scripts.

**Problem.** Formats are defined (`finding-schema.md`, the briefs' output sections,
`report-template.md`, `readiness-format.md`) but only partly enforced. The weak spots:

1. **Silent drops:** `assemble-report.sh` finds a finding's severity and action by exact
   field text (`- **Severity:** major`); a finding written slightly differently is left out
   of the report with no error, so a major could vanish.
2. The report header's counts are copied by hand by the orchestrator from the verification
   summary.
3. Nothing checks that the manifest has its required items.
4. `readiness.md` and the readiness analysts' files are not checked beyond the first line
   and size, including whether each edit's "Before" text exists in the issue description.
5. The readiness apply step's text replacement and decisions section are done by hand.
6. No format version in the exchanged files, so a resumed run after an update could mix
   formats.
7. No machine-readable findings file for `improve-agent-process` to count from.

**Design.** Keep markdown as the exchange format (models write it reliably; people can
audit it), and enforce it at every hand-off:

1. **One contracts reference** (in each skill's `references/`): every file exchanged, who
   writes it, who reads it, its required sections and fields, and which script validates it.
2. **A validator after every subagent,** failing loudly so the output goes back to its
   author instead of losing content:
   - `verified.md`: every confirmed finding has a parseable severity, action and location;
     minor-table rows have valid actions; counts agree with the verification summary;
   - `root-cause.md`: failure classes come from the tracked list;
   - the readiness analysts' files and `readiness.md`: required sections, Q/A/E IDs with
     reply lines, and each edit's "Before" text present verbatim in the issue description;
   - the manifest: its required items present.
3. **Script-computed counts** for the report header, replacing the orchestrator's copying.
4. **A script for the readiness apply step:** the accepted edits and the decisions section,
   applied mechanically from the round's file and the decision lines.
5. **A format version line** in each exchanged file, checked when a run resumes.
6. **A `findings.json` sidecar,** written by `assemble-report.sh` from `verified.md`
   (findings with severity, action, failure class, location, changed-or-unchanged code,
   harness version), for `improve-agent-process` to count from. This also covers the
   "machine-readable block per round" idea from the loop audit.

