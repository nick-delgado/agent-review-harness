# Report layout

The report is one GitHub comment. It is read top-down by someone deciding whether to merge,
so the decision and the findings come first and the audit trail sits in collapsed sections
underneath.

`scripts/assemble-report.sh <RUN_DIR>` builds it. You write two small files; the script
copies everything else from the phase outputs, unchanged.

## What you write

### `RUN_DIR/report-head.md`

```markdown
## Agent PR review: <verdict>

**PR:** #<n> <title> · **Head:** `<short sha>` · **CI:** <passing | failing: names | pending | none> · **Spec:** <issue #m (link) | path/to/spec.md | none found>

<Two or three sentences: what the PR does, the most important problem, and the main thing
the cause analysis points at.>

Confirmed findings after verification (<reported> reported, <confirmed> confirmed, <merged> merged, <rejected> rejected):

| | Blocker | Major | Minor | Nit |
|---|---|---|---|---|
| Standards | | | | |
| Code smells | | | | |
| Spec alignment | | | | |
| Test adequacy | | | | |

<If proposals exist that edit a doc, prompt or skill:> A PR with the proposed doc and skill changes can be opened on request.
```

Count each confirmed finding under the reviewer whose ID it kept. Take the numbers from
the verification summary in `verified.md`; do not recount by hand.

### `RUN_DIR/report-meta.md`

```markdown
- Reviewed commit: `<full head sha>` against `<base ref>`
- Reviewing agent and model: <tool, model>
- Reviewers: standards, code-smells, spec-alignment, test-adequacy; verifier; root-cause analyst
- Isolation: <parallel subagents with fresh context | none (sequential, shared context)>
- Tests, linters and builds were not run by this review; CI status is reported as found.
- <Anything that did not complete: a reviewer that failed, a phase skipped, and why.>
```

## Verdict

| Verdict | When |
|---|---|
| **Changes required** | any confirmed blocker |
| **Changes recommended** | no blocker, at least one confirmed major |
| **Acceptable** | only minor findings and nits, or none |

Add `— limited review` to the verdict when spec alignment was not reviewable or a reviewer
could not complete. The verdict is a recommendation to the human who merges.

## What the script assembles

| Report section | Taken from |
|---|---|
| Header, summary, counts | `report-head.md` |
| Findings (blocker and major, full blocks) | `verified.md` → Confirmed findings |
| Minor findings and nits (collapsed table) | `verified.md` → Minor findings table |
| Spec alignment (traceability, unrequested changes) | `verified.md` → Reviewer tables |
| Why this happened (cause per finding, patterns, not explained) | `root-cause.md` → Cause summary, Patterns, Not explained |
| Proposed process improvements | `root-cause.md` → Proposals |
| Evidence of review: counts of checks, searches and skipped items per reviewer | `findings/*.md` |
| Not reviewed (collapsed, always in full) | `findings/*.md` → 3. Not reviewed |
| Findings rejected or merged in verification (collapsed, always in full) | `verified.md` |
| Every check performed (collapsed, only when it fits) | `findings/*.md`, `verified.md` → Behaviour coverage |
| Run metadata (collapsed) | `report-meta.md` |

## Length

GitHub limits a comment to 65,536 characters. The script keeps the report under 60,000:

1. It builds the report with the full check tables.
2. If that is too long, it leaves the check tables out and says so in the run metadata. The
   per-reviewer counts, the "Not reviewed" list and the rejected findings always stay.
3. If it is still too long, it fails and prints the size of each section. Shorten the
   largest section in its source file (usually the proposals in `root-cause.md`) and run it
   again. Never shorten blocker or major findings, the "Not reviewed" list, or the rejected
   findings.
