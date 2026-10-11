## Goal
Implement the production Transcriber per ADR-006 and the S-3 spike findings.

**PRD:** FR-022, FR-023, FR-024, NFR-002 · **ADRs:** ADR-006 · **Task ID:** `S6-02` · **Stream:** `voice`

## Acceptance criteria
- [ ] AudioWorklet downsampling to 16 kHz PCM s16le, ~100 ms chunks
- [ ] Lazy-loaded `@aws-sdk/client-transcribe-streaming`; credentials from Cognito Identity Pool using the ID token. The pool is `/sched/<env>/auth/identity-pool-id` with the login `cognito-idp.us-east-1.amazonaws.com/<userPoolId>` (PR #94 hand-off).
- [ ] The SPA is configured with the Identity Pool ID (drift-audit decision 15, 2026-10-04; this replaces PR #120's hand-off to #28): `identityPoolId` is added to `Amplify.configure` in `apps/web/src/auth/authService.ts`, from a build-time `VITE_IDENTITY_POOL_ID` read by `apps/web/src/auth/config.ts` beside the pool and client IDs, and documented in `apps/web/.env.example`. `scripts/deploy-web.sh` (#100, merged) already passes it from SSM and fails without it (`scripts/deploy-web.sh:77-102`), so a deployed build always has it; #29 doesn't change the script. When it's missing (the dev server on the Cognito mock), voice doesn't try a real stream: the mic is hidden with an explanation, or the MockTranscriber is used; agent decides; list in the PR.
- [ ] The first real stream verifies that the Identity Pool role allows `transcribe:StartStreamTranscriptionWebSocket` (a stream with a signed-in demo user's Identity Pool credentials returns a transcript) and nothing else (the role's only policy lists that one action, and one other call with the same credentials, such as `transcribe:ListTranscriptionJobs`, is denied) (PR #94: the permission "hasn't been exercised yet; #29's first real stream does that"); result in the PR, with no credentials or account IDs in it.
- [ ] Stream starts on record. On Send (or the 60 s auto-send), the audio ends with an empty `AudioEvent` while the input stays open, and `stop()` resolves when Transcribe ends the response stream with the final results (ADR-006 "For #29": ending the input iterable makes the SDK close the socket at once, and the finals are lost). A test with a fake Transcribe client shows the empty event is sent and the input isn't ended before the response stream ends. Cancel closes the stream and discards everything (ADR-006). Errors (credentials, WebSocket, Transcribe exceptions, the mic track ending) reach #28's overlay through the `Transcriber` interface, which shows the FR-024 retry / type-instead; the stream is never retried automatically. The 10 s FR-024 timeout after Send is #28's overlay timer (drift-audit decision 4); the real Transcriber closes its stream when the overlay gives up, tested with a fake Transcribe client that never returns a final result.
- [ ] Stop→final p95 ≤ 2 s (from Send, or the 60 s auto-send, to the last final result) measured on Chrome (desktop), Safari (macOS), iOS Safari and Android Chrome over at least 20 utterances each, mixing ~5 s, 20 s and 60 s clips as in #10; Firefox and Edge are best effort (drift-audit decision 4, NFR-006); results in PR, per browser: stop→final p95 (a final that arrives before Send counts as 0 ms), Send→stream end p95, and the number of failed streams (an error, the socket closing before the final results, or no final within 10 s of Send; ADR-006 Validation, #10 r1/Q-2). Runs hidden on purpose don't count. A browser that misses 2 s is reported with its numbers and gets a follow-up issue; it doesn't block this PR. A measured browser with more than one failed stream meets ADR-006's "Revisit if": it is reported first in the PR and gets a follow-up issue for the batch fallback, which this issue doesn't build.

## Owned paths
- `apps/web/src/voice/transcribe/**`
- `apps/web/public/worklets/**`
- `apps/web/src/voice/**` outside `transcribe/` (choosing the real or mock Transcriber, and the missing-config state; call it out in the PR)
- `apps/web/src/auth/authService.ts`, `apps/web/src/auth/authService.test.ts`, `apps/web/src/auth/config.ts`, `apps/web/src/auth/config.test.ts`, `apps/web/src/auth/env.d.ts` (the Identity Pool ID)
- `apps/web/src/auth/session.ts`, `apps/web/src/auth/session.test.ts`, `apps/web/src/auth/index.ts`, `apps/web/src/auth/testing.ts` (a credentials getter beside `getIdToken`, and the fake `AuthService` that implements it)
- `docs/journal/**` (an entry for the choices this issue leaves to the agent)
- `docs/architecture.md` (the "Voice input" section's *Planned* note at `:70` and voice in the not-yet-live list at `:5`; a shared file, so call it out in the PR)
- `apps/web/.env.example`, `apps/web/README.md` (the Identity Pool ID)
- `apps/web/package.json`, `package-lock.json` (the lazy-loaded Transcribe client and a credentials provider; shared files, call them out in the PR)
- `apps/web/build.test.ts` (if the lazy load is checked in the build test, the way #24/#25 check the mocks)

## Non-goals
- No batch-transcription fallback (ADR-006 "Revisit if"); a browser that misses the latency target gets a follow-up issue.
- No change to `infra/stacks/auth.yaml`, the bootstrap permissions boundary or `scripts/deploy-web.sh`; if the role check fails, report it and file an issue.
- No live captions of partial results (ADR-006: partial results are buffered).

## Dependencies
Blocked by:
- #28 (S6-01)
- #12 (S1-01)
- #10 (M1-08)

Related: #100 passes `VITE_IDENTITY_POOL_ID` to the build (drift-audit decision 15).

Unblocks: #36 (M3-01)

## References
- ADR-005 (auth, Identity Pool), ADR-006 (voice input)
- PR #94 "Deferred / follow-ups" (Identity Pool ID and login provider; the untested Transcribe permission)
- PR #120 follow-ups (the Identity Pool hand-off, moved here)
- `infra/stacks/auth.yaml` (the Transcribe-only Identity Pool role and the `identity-pool-id` SSM parameter)
- CLAUDE.md (architecture rules + definition of done)
- docs/PRD.md
- `task-workflow` skill

## Decisions and clarifications

Settled before work started, by the owner, in answer to readiness reviews. Coding agents and PR reviewers treat these as part of the spec.

- **r1/Q-1:** Once the Identity Pool is configured, should text chat keep working when Cognito can't issue AWS credentials? → (a) Keep the token path independent: `getIdToken` reads tokens through Amplify's token provider (`Amplify.Auth.getTokens()`, the same call `fetchAuthSession` makes first, which also refreshes). Voice alone calls `fetchAuthSession()` for credentials. A test with a failing Cognito Identity endpoint shows `getIdToken` still returns the token. Scope: within the issue (`authService.ts` and its test are owned). ([answer](https://github.com/nick-delgado/serverless-ai-scheduling/issues/29#issuecomment-5985126356))
- **r1/Q-2:** Does #29 switch the app to the real Transcriber, or does #36? → (a) #29 does the switch: one factory under `apps/web/src/voice/` picks the real Transcriber when the Identity Pool ID is configured, or the missing-config behaviour otherwise, and #28's mic uses it. After #29 merges, the deployed app streams for real, and #36's criterion only checks it end to end. If #28 constructs the Transcriber in `ChatPage.tsx`, a one-line change there is called out as a shared-file change. Scope: within the issue, with E-7's wording. ([answer](https://github.com/nick-delgado/serverless-ai-scheduling/issues/29#issuecomment-5985126356))
- **r1, edits:** E-1 to E-7 accepted ([answer](https://github.com/nick-delgado/serverless-ai-scheduling/issues/29#issuecomment-5985126356)) and applied above; see the [readiness review](https://github.com/nick-delgado/serverless-ai-scheduling/issues/29#issuecomment-5984846557).
- **r1, assumed (A-1):** Transcribe credentials come from Amplify's `fetchAuthSession().credentials`. No `@aws-sdk/credential-providers` is added, so the owned-paths allowance for "a credentials provider" goes unused. Amplify builds the login map from the ID token's issuer, so the `cognito-idp.<region>.amazonaws.com/<userPoolId>` key from PR #94 comes out right without hard-coding it.
- **r1, assumed (A-2):** `VITE_IDENTITY_POOL_ID` is optional and stays outside `resolveCognitoConfig`'s "set both or neither" rule (`apps/web/src/auth/config.ts:23-31`). A missing ID never breaks sign-in; it only takes voice off the real path. On the Cognito mock fallback the ID is ignored, because mock tokens can't be exchanged. (would have asked)
- **r1, assumed (A-3):** Missing-config state (AC3 leaves this to the agent): the dev server on the Cognito mock uses the MockTranscriber, kept out of production builds the way `main.tsx:14-18` drops the mock API. Any other build without the ID shows the mic disabled with a one-line explanation rather than hiding it, so FR-020's "Mic button next to the text input" (`docs/PRD.md:73`) still holds. Listed in the PR.
- **r1, assumed (A-4):** The Transcribe client's region comes from the Identity Pool ID's prefix (`us-east-1:…`), as Amplify does for Cognito Identity. No `VITE_REGION` is added.
- **r1, assumed (A-5):** `@aws-sdk/client-transcribe-streaming` is loaded with a dynamic `import()` the first time the mic is used. `apps/web/build.test.ts` checks that the entry chunk `index.html` references doesn't contain it and that another chunk does.
- **r1, assumed (A-6):** Capture starts when recording starts, and chunks are held until the WebSocket opens, so the first words aren't lost. Chunks are 1600 samples (3200 bytes, 100 ms); anything in ADR-006's 50-200 ms range is acceptable. Downsampling and s16le encoding are a pure module, unit-tested in jsdom, and the worklet is thin. The worklet goes in `public/worklets/` or `src/` via a Vite URL import, whichever keeps `npm run lint` and `typecheck` green. Any `eslint.config.js` change is called out as a shared-file change.
- **r1, assumed (A-7):** Stream parameters: `en-US`, `pcm`, 16000 Hz, PII redaction off, no custom vocabulary, no partial-results stabilization unless #10 recommends it. Partials aren't shown. The transcript is the first alternative of each `IsPartial: false` result in order, joined with spaces and trimmed. A stream with no final result gives an empty transcript, which #28 shows as FR-023's "I didn't catch that".
- **r1, assumed (A-8):** Errors (credentials, WebSocket close, Transcribe exceptions, mic track ended) are reported through #28's `Transcriber` interface, and #28's overlay shows FR-024's retry / type-instead. The stream is never retried automatically. #28's overlay owns the 10 s timer, and the real Transcriber closes its stream when the overlay gives up or cancels (see E-3).
- **r1, assumed (A-9):** Cancel, Esc, unmount and sign-out close the WebSocket and discard everything. The mic track and AudioContext are released after each recording, so the browser's mic indicator turns off. No audio is stored.
- **r1, assumed (A-10):** AC4 runs once, with a signed-in demo user, on the env used for AC6. If the stream is denied, the agent doesn't change `infra/stacks/auth.yaml` or the bootstrap boundary. It reports the denial first and files an issue (see E-6).
- **r1, assumed (A-11):** Measurement setup: timing comes from `performance.now()` at Send and at the last final result, logged in dev builds only, never shown in production. Runs use an ephemeral env (`scripts/deploy.sh all <name>`, then `scripts/deploy-web.sh <name>` with seeded users), as `deploy-web.sh:62-65` advises for unmerged branches. Publishing the branch over shared `dev` happens only after asking Nick. iOS Safari and Android Chrome need Nick's devices, so the agent lists those runs first in its report. (would have asked) — superseded by r2/Q-2 (measurement method)
- **r1, assumed (A-12):** Docs: the `src/voice/` row of `apps/web/README.md:20` and the config line at `:29` are updated for S6-02 and the third ID. A journal entry records the choices the issue leaves to the agent (see E-5 for the path). The 2026-10-03 journal line saying "#28 (voice) adds the Identity Pool" stays as dated history. `scripts/deploy-web.sh` isn't changed, though its bundle check greps only for the user pool ID (`:107-111`); a matching Identity Pool check would be a follow-up issue.
- **r1, reuse** (from the readiness review, as of `9b2c17b`; carried over by hand on 2026-10-08, since the round-1 apply step at harness 2026.10.04.4 left it out):
  - `resolveCognitoConfig` and `CognitoEnv` (`apps/web/src/auth/config.ts:13-31`): read the third ID the same way. `session.ts:14-19` already passes all of `import.meta.env`, so no `session.ts` change is needed just to read it.
  - The single `Amplify.configure` call (`apps/web/src/auth/authService.ts:68-75`).
  - Amplify's `fetchAuthSession().credentials` for the Transcribe client, and `Amplify.Auth.getTokens()` for a token-only path (Q-1 (a)).
  - The dynamic-import pattern in `apps/web/src/main.tsx:14-18`.
  - The build harness and forbidden-string scan in `apps/web/build.test.ts:22-45`, `:60-79`.
  - The env-stub test pattern in `apps/web/src/auth/session.test.ts:25-53`.
  - MSW with `onUnhandledFrame: "error"` (`apps/web/src/test/setup.ts:13`): any test that would open a real WebSocket fails loudly.
  - `globals.audioWorklet` from the root `globals` dependency, if a worklet lint block is added.

