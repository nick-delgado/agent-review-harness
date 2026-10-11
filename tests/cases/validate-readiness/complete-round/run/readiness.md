<!-- agent-pr-review:readiness round=1 -->
## Readiness review (round 1): Needs answers

Round: 1 · Questions: 1 · Assumptions: 2 · Suggested edits: 1 · Spec commit: bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb · Harness version: 2026.10.06.3

**Check these first:** none

### Questions

#### Q-1: How many retries?

- **Options:** (one per line)
  - (a) One retry: simplest. Scope: within the issue
  - (b) Three retries with backoff: matches the client. Scope: within the issue
  - (c) Configurable: adds a setting. Scope: adds a config key
- **Makes stale:** `docs/send.md:30` under (b) and (c) ("sends once")
- **Edges:** a send that fails on the third retry is reported failed, not retried again;
  two concurrent sends retry independently; the evidence is `test/send.test.ts`.
- **Recommendation:** (b), because the client does three.
- **Reply:** `Decision r1/Q-1: (b)`

### Assumptions

| ID | Assumption | Basis | Makes stale | To correct |
|---|---|---|---|---|
| A-1 | The agent puts the retry loop in `src/send.ts` (suggestion) | convention | `docs/send.md:12`<br>`test/send.test.ts:40` ("sends once") | `Decision r1/A-1: <your correction>` |
| A-2 | Errors are logged once | ADR-2 | nothing | `Decision r1/A-2: <your correction>` |

### Suggested edits to the issue

#### E-1: add a verification section

Before:
```text
- [ ] A failed send is retried.
```
After:
```text
- [ ] A failed send is retried up to three times.

## Verification
- Run the send tests.
```
- **Reply:** `Decision r1/E-1: accept`

### Reuse, dependencies and risks

- **Reuse:** import `withBackoff` from `src/util/retry.ts:8`;
  move `isTransient` from `src/client.ts:40` to `src/util/errors.ts` and import it from both
  (adds owned path `src/util/errors.ts`)
- **Dependencies:** none

**Relied on:** `docs/adr/0002.md` "Logging"
