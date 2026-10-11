## Goal
Offer a retry.

## Acceptance criteria
- When a 5xx arrives without an event, a Retry button is shown and resends the last message.

## Owned paths
- `apps/web/src/chat/`
- `packages/agent/src/retry.ts`

## Verification
- npm test

## Decisions and clarifications

Settled before work started, in answer to readiness reviews: the owner's answers, and the assumptions the owner let stand. Coding agents and PR reviewers treat these as part of the spec.

- **r1/Q-1** (settled against `abcdef1`): Should a retry reuse the conversation? → (b) Start a new one and move the shared helper. Scope: adds files. Owned paths: + `packages/agent/src/retry.ts` (accept all, [answer](https://github.test/c/2))
  - not chosen: (a) Reuse it: the first-turn retry continues. Scope: within the issue
- **r1/Q-2** (settled against `abcdef1`): What about a 4xx? → (a) No retry. Scope: within the issue (accept all, [answer](https://github.test/c/2))
  - not chosen: (b) Retry once. Scope: within the issue
- **r1, assumed** (as of `abcdef1`):
  - A-1: The button reads "Retry".
  - A-2: The SDK returns status on truncation (verify first) (confirmed, [answer](https://github.test/c/2))
  - A-3: Retries are logged.

