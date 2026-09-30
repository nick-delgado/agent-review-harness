# Report template

The report is one GitHub comment. It is read top-down by someone deciding whether to merge,
so the decision and the findings come first, and the audit trail sits in collapsed sections
underneath.

## Assembly rules

- Keep the first line exactly as shown: the posting script finds earlier reports by it.
- Copy findings, tables and ledgers from `verified.md`, `root-cause.md` and
  `findings/*.md`. Do not change severities, drop findings or paraphrase quotes.
- A section with nothing in it stays, with the reason ("No spec found", "No confirmed
  findings, so no cause analysis was run"). An absent section reads as an unperformed check.
- GitHub limits a comment to 65,536 characters. If the report is over 60,000, trim in this
  order and say in the run metadata what was trimmed: (1) coverage ledgers reduced to the
  "Checks performed" tables; (2) nits reduced to a count; (3) minor findings reduced to the
  table row without the detail block. Never trim blocker or major findings, rejected
  findings, or the "Not reviewed" list.

## Verdict

| Verdict | When |
|---|---|
| **Changes required** | any confirmed blocker |
| **Changes recommended** | no blocker, at least one confirmed major |
| **Acceptable** | only minor findings and nits, or none |

Add `— limited review` to the verdict when spec alignment was not reviewable or a reviewer
could not complete. The verdict is a recommendation to the human who merges.

## Template

````markdown
<!-- agent-pr-review:report -->
## Agent PR review: <verdict>

**PR:** #<n> <title> · **Head:** `<short sha>` · **CI:** <passing | failing: names | pending | none>

<Two or three sentences: what the PR does, the most important problem, and the main thing
the root-cause analysis points at.>

| | Blocker | Major | Minor | Nit |
|---|---|---|---|---|
| Standards | | | | |
| Code smells | | | | |
| Spec alignment | | | | |
| Test adequacy | | | | |

### Findings

<Blockers, then majors: the full block for each.>

#### <ID> · <severity> · <title>
`path/file.ext:120-134`
```<lang>
<quoted code>
```
**Measured against:** <source> — "<quote>"
**Why it matters:** <...>
**Suggested fix:** <...>

<details>
<summary>Minor findings and nits (<count>)</summary>

| ID | Severity | Location | Problem | Suggested fix |
|---|---|---|---|---|

</details>

### Spec alignment

**Spec source:** <issue #m (link) | path/to/spec.md | none found>

| Req | Requirement | Status | Evidence |
|---|---|---|---|

**Unrequested changes:** <table or "None.">

### Why this happened

These are inferences from the repository. The agent's prompt and transcript were not
available.

| Finding | Primary cause | Confidence | Evidence |
|---|---|---|---|

**Patterns:** <the grouped causes, one line each>

### Proposed process improvements

<For each proposal, ordered as in root-cause.md:>

#### P1 · <type> · <title>
**Prevents:** <finding IDs> · **Confidence:** <...> · **Target:** `path`
```diff
<the exact change>
```
**Expected effect:** <...> · **Cost:** <...>

<If proposals exist:> _I can open a PR with the doc and skill changes above on request._

### Evidence of review

<details>
<summary>What was reviewed (<n> files, <n> rules, <n> requirements, <n> checks)</summary>

**Inputs:** <standards sources, spec sources, direction sources, process inventory, from the manifest>

**Standards:** <Checks performed table>
**Code smells:** <Checks performed and Searches run tables>
**Spec alignment:** <Checks performed table>
**Test adequacy:** <Behaviour coverage table>

</details>

<details>
<summary>Not reviewed (<count>)</summary>

<Every "Not reviewed" item from every reviewer, and every gap from the manifest.>

</details>

<details>
<summary>Findings rejected in verification (<count>)</summary>

| ID | Claim | Reason rejected | What was checked |
|---|---|---|---|

**Verification summary:** <the per-reviewer table>

</details>

<details>
<summary>Run metadata</summary>

- Reviewed commit: `<full head sha>` against `<base ref>` (`<base sha>`)
- Reviewing agent and model: <tool, model>
- Reviewers: standards, code-smells, spec-alignment, test-adequacy; verifier; root-cause analyst
- Isolation: <parallel subagents with fresh context | none (sequential, shared context)>
- Tests, linters and builds were not run by this review; CI status is reported as found.
- Trimmed for length: <nothing | what>

</details>
````
