<!-- agent-pr-review:readiness round=1 -->
## Readiness review (round 1): Needs answers

Round: 1 · Questions: 2 · Assumptions: 3 · Suggested edits: 2 · Spec commit: abcdef1234567890 · Harness version: 2026.10.06

**Check these first:** A-2

### Questions

#### Q-1: Should a retry reuse the conversation?

- **Options:**
  - (a) Reuse it: the first-turn retry continues. Scope: within the issue
  - (b) Start a new one and move the shared helper. Scope: adds files. Owned paths: + `packages/agent/src/retry.ts`
- **Recommendation:** (b), because the PRD says so.
- **Reply:** `Decision r1/Q-1: (b)`

#### Q-2: What about a 4xx?

- **Options:**
  - (a) No retry. Scope: within the issue
  - (b) Retry once. Scope: within the issue
- **Recommendation:** (a), because errors are final.

### Assumptions

| ID | Assumption | Basis | Makes stale | To correct |
|---|---|---|---|---|
| A-1 | The button reads "Retry". | UI copy | nothing | `Decision r1/A-1: ...` |
| A-2 | The SDK returns status on truncation (verify first) | docs | nothing | x |
| A-3 | Retries are logged. | convention | nothing | x |

### Suggested edits to the issue

#### E-1: make the criterion testable

Before:
```text
- Retry works.
```
After:
```text
- When a 5xx arrives without an event, a Retry button is shown and resends the last message.
```

#### E-2: stale verification

Before:
```text
- npm run e2e
```
After:
```text
- npm test -w web
```
