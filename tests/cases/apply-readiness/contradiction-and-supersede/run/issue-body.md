## Goal
Retry failed sends.

## Acceptance criteria
- [ ] A failed send is retried up to three times.

## Verification
- Run the send tests.

## Owned paths
- `src/send.ts`

## Decisions and clarifications

Settled before work started, by the owner, in answer to readiness reviews. Coding agents and PR reviewers treat these as part of the spec.

- **r1/Q-1** (settled against `bbbbbbb`): How many retries? → (b) Three retries with backoff: matches the client. Scope: within the issue (accept all, [answer](https://x/9))
  - edges: a send that fails on the third retry is reported failed, not retried again; two concurrent sends retry independently; the evidence is `test/send.test.ts`.
  - not chosen: (a) One retry: simplest. Scope: within the issue
  - not chosen: (c) Configurable: adds a setting. Scope: adds a config key
- **r1, assumed** (as of `bbbbbbb`):
  - A-1: The agent puts the retry loop in `src/send.ts` (suggestion) (makes stale: `docs/send.md:12`; `test/send.test.ts:40` ("sends once"))
  - A-2: Errors are logged once
- **r1, reuse** (from the readiness review, as of `bbbbbbb`): import `withBackoff` from `src/util/retry.ts:8`;
  move `isTransient` from `src/client.ts:40` to `src/util/errors.ts` and import it from both
  (adds owned path `src/util/errors.ts`)

