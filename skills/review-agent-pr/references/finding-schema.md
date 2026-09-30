# Output format for reviewers

Every reviewer writes one markdown file with the three sections below, in this order. The
verifier and the report are built from these files, so keep the headings and field names
exactly as shown.

## 1. Findings

One block per finding. If there are none, write `No findings.` under the heading.

```markdown
### <ID>: <one-line statement of the problem>

- **Severity:** blocker | major | minor | nit
- **Confidence:** high | medium | low
- **Category:** <reviewer-specific category, see your brief>
- **Location:** `path/to/file.ext:120-134` (add more lines for more locations)
- **Evidence:**
  ```<lang>
  <the code, quoted exactly from the PR head, trimmed to the relevant lines>
  ```
- **Measured against:** <source path:line or URL> — "<the rule, spec clause or precedent, quoted exactly>"
- **Why it matters:** <the concrete consequence, in one or two sentences>
- **Suggested fix:** <what to change; name the existing function, pattern or doc to use>
- **Introduced by this PR:** yes | worsened | pre-existing (only report pre-existing when the PR depended on it)
```

IDs use the reviewer's prefix and a running number: `STD-1`, `SMELL-1`, `SPEC-1`, `TEST-1`.

### Severity

| Level | Meaning |
|---|---|
| blocker | Must not merge: contradicts the spec or a documented hard rule, breaks an architectural boundary, removes or disables verification, or ships placeholder behaviour as real. |
| major | Should be fixed before merge: a clear violation of a documented standard, a missing requirement, duplicated logic that will drift, behaviour without a meaningful test. |
| minor | Worth fixing, safe to merge without: local maintainability issues, weak but present tests, small unrequested changes. |
| nit | Optional polish. Report at most five per reviewer. |

### Rules for a valid finding

- The quoted code exists at the stated location in `<RUN_DIR>/worktree`.
- The "Measured against" quote exists at the stated source. If the measure is a precedent
  rather than a written rule, cite at least two existing places in the codebase that follow
  it, and cap the severity at minor.
- A personal preference with no rule, spec clause or precedent behind it is not a finding.
- Anything the manifest lists as machine-enforced (lint, format, types, CI checks) is not a
  finding. CI will report it.
- Problems that already existed and that the PR neither worsened nor relied on are out of
  scope.

## 2. Coverage ledger

This is the evidence of what you did. Record checks that passed as carefully as the ones that
failed: the reader uses this section to decide how far to trust the review.

```markdown
### Sources read
| Source | Why |
|---|---|
| `AGENTS.md` | standards |
| `src/billing/invoice.ts` (full file) | changed file |

### Checks performed
| # | Check | Scope | Result |
|---|---|---|---|
| 1 | <what was checked, specific enough to repeat> | <files or rule> | pass / finding <ID> / not applicable |

### Searches run
| Query or command | Purpose | Hits |
|---|---|---|
| `grep -rn "formatCurrency" src/` | look for an existing equivalent of the new `toMoney` helper | 3 |
```

## 3. Not reviewed

List everything in your remit that you did not or could not check, with the reason: a file
too large to read fully, a spec that was not accessible, a rule too vague to test, generated
or vendored files skipped. Write `Nothing skipped.` if that is true.
