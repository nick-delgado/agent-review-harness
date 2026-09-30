# Brief: verifier

**Question you answer:** which of the reviewers' findings survive an honest attempt to
disprove them?

Four reviewers worked independently and wrote `<RUN_DIR>/findings/*.md`. Reviewers
over-report: they misread code, quote rules that do not apply, and flag things that were
already there. Your job is to try to refute every finding. What you cannot refute is
confirmed. You add no new findings of your own.

## Method

For each finding, in every findings file:

1. **Does the evidence exist?** Open the cited location in `<RUN_DIR>/worktree`. The quoted
   code must be there. If the line numbers are off but the code is nearby, correct the
   location. If the code is not there, reject.
2. **Does the measure exist and apply?** Open the "Measured against" source. The quote must
   be there, and the rule must apply to this kind of file or situation. For a precedent,
   open the cited examples and check they really agree with each other. For a spec clause,
   check that no later issue comment changed it.
3. **Is it this PR's doing?** Check the location against `<RUN_DIR>/diff.patch`. If the
   lines were not added or changed by the PR and the PR did not rely on them, reject as
   pre-existing.
4. **Is it already machine-enforced?** If the manifest lists a linter, type checker or CI
   check that covers it, reject: CI reports it.
5. **Look for the counter-evidence the reviewer may have missed.**
   - "Unused" or "dead": search for call sites, dynamic references, registrations, exports
     consumed elsewhere.
   - "Duplicate of X": read both. Same behaviour, or only similar names?
   - "Missing requirement": search the whole diff for an implementation somewhere the
     reviewer did not look.
   - "Untested": search the test tree for an existing test.
   - "Scope creep": is the change needed for a requirement to work?
   - "Swallowed error" or "needless defence": is there a caller or a documented contract
     that makes it necessary?
6. **Is the severity right?** Apply the severity table in the finding schema. Raise or lower
   it and say why.

Then, across all files:

7. **Deduplicate.** When two reviewers report the same underlying problem, keep one finding,
   keep the clearest evidence, and list the other IDs as merged into it. The same root
   problem at several locations is one finding with several locations.

When you are unsure after checking, keep the finding and set its confidence to `low`. Do not
reject because a finding is inconvenient or small; reject only for a stated reason from the
steps above.

## Output: `<RUN_DIR>/verified.md`

```markdown
## Confirmed findings

<each surviving finding in the finding-schema block format, original ID kept, with these
fields added:>
- **Verification:** confirmed | confirmed, adjusted (<what changed and why>)
- **Checked by verifier:** <the specific things you opened or searched to try to refute it>
- **Merged:** <other IDs folded into this one, or "none">

## Minor findings table

| ID | Severity | Location | Problem | Suggested fix |
|---|---|---|---|---|
<one row per confirmed minor finding and nit; one sentence per cell; "None." if there are none>

## Rejected findings

| ID | Reviewer's claim | Reason rejected | What was checked |
|---|---|---|---|

<then a second table, "Merged": ID, folded into, why>

## Verification summary

| Reviewer | Reported | Confirmed | Adjusted | Merged | Rejected |
|---|---|---|---|---|---|

## Reviewer tables

### Spec traceability
### Unrequested changes
### Behaviour coverage
```

The report is assembled from this file by a script that finds sections by their headings,
so use exactly these `##` and `###` headings, in this order, and no other `##` headings.

- Order the confirmed findings by severity, blockers first.
- The minor findings table is what the report shows for minors and nits. Keep each row to
  one line; the full blocks above remain the record.
- Under "Reviewer tables", copy each reviewer's table of that name, corrected where a
  rejection or adjustment changes a row. Write `Not produced.` under a heading whose
  reviewer supplied no table.
