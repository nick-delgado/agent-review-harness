<!-- agent-pr-review:readiness round=2 -->
## Readiness refresh (round 2): Needs answers

Round: 2 · Questions: 1 · Assumptions: 1 · Suggested edits: 0 · Spec commit: cccccccccccccccccccccccccccccccccccccccc · Harness version: 2026.10.11

**Check these first:** none

### Questions

#### Q-1: Are errors logged per attempt? (reopens r1/A-2)

- **Options:** (one per line)
  - (a) Once per send. Scope: within the issue
  - (b) Once per attempt. Scope: within the issue. Owned paths: + `src/log.ts` (the `logAttempt` helper only), + `test/log.test.ts`
- **Makes stale:** `docs/send.md:30` (says "logged once")
- **Edges:** none: one send, one log stream.
- **Recommendation:** (a), because ADR-2 says once.
- **Reply:** `Decision r2/Q-1: (b)`

### Assumptions

| ID | Assumption | Basis | Makes stale | To correct |
|---|---|---|---|---|
| A-1 | Under Q-1 (a), the log line names the send ID | ADR-2 | nothing (the doc has no example) | `Decision r2/A-1: <your correction>` |
