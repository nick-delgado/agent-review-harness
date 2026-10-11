## Summary

Two findings.

## Confirmed findings

### SPEC-1: Built to the old FR-030

- **Severity:** major
- **Location:** `src/a.ts:10`
- **Action:** fix now
- **Spec moved:** `abc1234` changed `docs/PRD.md` "FR-030" after the work began
- **Suggested fix:** follow the new text
- **Done when:** the new limit holds

### SPEC-2: A blocker offered for deferral

- **Severity:** blocker
- **Location:** `src/b.ts:4`
- **Action:** needs owner decision
- **Decision needed:** fix here or later?
- **Options:**
  - (a) Fix it here. Scope: within the issue
  - (b) Defer to #212: its criterion 3 covers this. Scope: moves to #212
- **Recommendation:** (a), because it is a blocker.

### TEST-1: Deferral done right

- **Severity:** minor
- **Location:** `test/c.test.ts:7`
- **Action:** needs owner decision
- **Decision needed:** add the test here or in #212?
- **Options:**
  - (a) Add it here. Scope: within the issue
  - (b) Defer to #212: "a test pins the retry count" (criterion 2). Scope: moves to #212
- **Recommendation:** (a), because it is small.

## Minor findings table

| ID | Severity | Action | Location | Problem | Suggested fix |
|---|---|---|---|---|---|
| None. | | | | | |

## Rejected findings

None.

## Spot checks

None.

## Previous findings

No previous review.

## Convergence

First review.

## Verification summary

| Reviewer | Reported | Confirmed | Adjusted | Merged | Rejected |
|---|---|---|---|---|---|

## Reviewer tables

### Spec traceability
### Unrequested changes
### Behaviour coverage
