<!-- agent-pr-review:readiness round=2 -->
## Readiness refresh (round 2): Needs answers

**Issue:** #29 [S6-02] Real Transcriber: AudioWorklet PCM → Transcribe Streaming via Identity Pool credentials · **Read at:** 2026-10-09 10:32 UTC · **Default branch:** `main` @ `a6c8cca`

Round 1's answers were settled against `main` @ `9b2c17b` (2026-10-04). This refresh checks them against `main` @ `a6c8cca`. Since then spike S-3 (#10, PR #225) accepted ADR-006 and added a "For #29" list, and #28 (PR #154) merged the `Transcriber` interface and the context #29 plugs into. Round 1's answers still hold. The ADR leaves one choice to Nick in #29: what happens when the page is hidden mid-recording. It also asks AC6 to report reliability and Send→stream end, and it describes a measurement method that differs from r1/A-11, which contradicts itself as written. AC5 doesn't yet say how the audio ends, and a wrong guess there loses every transcript.

Round: 2 · Questions: 2 · Assumptions: 4 · Suggested edits: 4 · Spec commit: a6c8cca3ad99602238e0da5c7a52dce7345da211 · Harness version: 2026.10.08.2

**Check these first:** A-3, A-1

**To answer:** reply on this issue with one line per item, in the form shown under each
(`Decision r2/<ID>: <answer>`): an option's letter or your own words for a question,
"accept" or "reject" for an edit, "ok" or your correction for an assumption. To take every
recommendation and edit at once, `Decision r2/ALL: accept`; it does not cover the
assumptions under "Check these first" or those marked "(verify first)" or "(would have
asked)", which each need their own line. Only `Decision` lines are applied, never other
replies. Then ask for the apply step, which writes your answers into the issue's description.

### Questions

#### Q-1: What should happen when the page is hidden (screen locked, app switched) while the patient is recording?

- **Why it matters:** on iOS, locking the screen or leaving Safari mid-recording silently drops the audio while the page is hidden, and the stream stays open (ADR-006 Consequences, `docs/adr/0006-voice-transcription.md:58`). Without a rule, the patient comes back and presses Send, and a transcript with a gap in the middle goes to the scheduling agent as their message. Android Chrome kept recording through a lock and a tab switch (`docs/adr/0006-voice-transcription.md:85`). The real Transcriber is the only code that can notice this. The overlay can't, because it never touches browser APIs (`apps/web/src/voice/transcriber.ts:1-22`).
- **Source:** ADR-006 "For #29" (`docs/adr/0006-voice-transcription.md:96`): "#29 should listen for `visibilitychange` and treat hidden-while-recording as an error (`onError`, then cancel), or warn the patient. Nick decides which in #29." The spike's journal recommends the error, on every browser (`docs/journal/2026-10-08-voice-streams-pass-but-the-sdk-hangs-up-early.md:37`). The issue is silent on this.
- **Options:**
  - (a) An error on every browser: when `document.visibilityState` becomes `hidden` while recording, the real Transcriber calls `onError` with a `failed` `TranscriberError`, stops the mic and closes the stream. #28's overlay then shows the FR-024 error with Record again / Type instead and calls `cancel()` (`apps/web/src/voice/useRecording.ts:147-149`). No interface or overlay change. Scope: within the issue.
  - (b) An error on iOS only: the same as (a), but only where the audio is known to stop, detected by user agent or by a chunk gap. Android keeps recording through a lock. Scope: within the issue. User-agent sniffing, or a gap threshold, is new logic to test.
  - (c) Warn the patient: keep the stream, and when the page is visible again, show a note in the overlay that part of the recording may be missing. This needs a new optional callback on the `Transcriber` interface and new overlay UI and copy. Scope: adds changes to #28's `transcriber.ts`, `useRecording.ts` and `RecordingOverlay.tsx` (all under `apps/web/src/voice/`, owned outside `transcribe/` only for the factory and the missing-config state today).
- **Edges:** only the recording phase counts. Hidden during "starting" (the permission prompt) or after Send ("Transcribing…", when the audio has already ended) is not an error under (a) or (b). Becoming visible again before Send doesn't undo (a)'s error. Under (a), a run that a tester hides on purpose during AC6 is not a failed stream (#10 r1/Q-2 edges). Evidence for (a): a jsdom test stubs `document.visibilityState` to `hidden`, dispatches `visibilitychange` while recording, and sees `onError` called with kind `failed` and the fake mic track stopped.
- **Recommendation:** (a), because it fits the interface #28 shipped (`onError` → FR-024 → `cancel()`), needs no new UI, and never sends a transcript with a silent gap. The spike's own recommendation (journal 2026-10-08) is the same. Android loses little: a patient who locks the phone mid-sentence records again.
- **Reply:** `Decision r2/Q-1: (a)`

#### Q-2: How are AC6's measurements taken and collected, given that A-11 logs timing "in dev builds only" but measures on a deployed build? (reopens r1/A-11)

- **Why it matters:** r1/A-11 says timing is "logged in dev builds only, never shown in production" and that runs use an ephemeral env published with `scripts/deploy-web.sh`. That script runs `npm run build` (`scripts/deploy-web.sh:101-102`), a production build where `import.meta.env.DEV` is false, so the timing log wouldn't be there. Since round 1, ADR-006 says "#29 AC6 re-measures reliability on the shipped code" (`docs/adr/0006-voice-transcription.md:79`) and asks for Send→stream end beside stop→final (`:93`). It also records the spike's different route: a local Vite dev server over HTTPS on the LAN, never deployed (`:63`). An agent that guesses could ship timing code in the production bundle, change a shared config, or reach the phone runs with no way to read the numbers. The phone runs need Nick, so a redo is expensive.
- **Source:** r1/A-11 (issue, "Decisions and clarifications"); ADR-006 Validation (`docs/adr/0006-voice-transcription.md:63`, `:78`, `:79`, `:93`); `scripts/deploy-web.sh:101-102`.
- **Options:**
  - (a) An opt-in build flag. The timing record (`performance.now()` at Send or the 60 s auto-send, at the last final result, and at the end of the stream) and a way to export it are compiled in only when `VITE_VOICE_TIMING=1` is set at build time. The AC4 and AC6 runs use an ephemeral env published with `VITE_VOICE_TIMING=1 scripts/deploy-web.sh <name>`: the script's build inherits the shell's environment, so it needs no change. Phones load the env over CloudFront HTTPS, so no certificates are needed. `dev` and other deploys leave the flag unset, and `apps/web/build.test.ts` shows a build without it contains no timing code. Scope: within the issue (`env.d.ts` and `build.test.ts` are owned).
  - (b) The spike's route: the `apps/web` dev server over HTTPS on the LAN, with `dev`'s real Cognito and Identity Pool IDs in `.env.local`, and timing logged behind `import.meta.env.DEV`, as A-11 says. Nothing is deployed, but this measures a dev build rather than the bundle that ships. Scope: adds an HTTPS option and a dev dependency (`@vitejs/plugin-basic-ssl` or mkcert, as #10 r1/Q-3). Owned paths: + `apps/web/vite.config.ts`
  - (c) Instrumentation in every build: `performance.mark` and `performance.measure` (no UI, no network) in all builds. Each run is read through Safari Web Inspector or `chrome://inspect` remote debugging on the ephemeral env from A-11. Scope: within the issue. That means reading at least 80 runs by hand over a cable.
- **Edges:** a final that arrives before Send counts as 0 ms (ADR-006 `:78`, Nick's decision on PR #225). The clip mix is the spike's three scripts, 7 × ~5 s, 7 × ~20 s and 6 × ~60 s (`:93`). The tester hides runs on purpose for Q-1, and those runs don't count. The evidence is a per-browser table in the PR (E-2's fields), with no credentials, pool IDs or account IDs in it. Under (a) and (c), the ephemeral env is torn down with `scripts/teardown.sh <name>` after the runs. AC4's role check runs on the same env (r1/A-10, still holds).
- **Recommendation:** (a), because it measures the bundle that ships, as ADR-006 asks for AC6 (`:79`). It also keeps timing code out of `dev`'s bundle, needs no certificate on Nick's phones, and changes no file outside the owned paths.
- **Reply:** `Decision r2/Q-2: (a)`

### Assumptions

The coding agent will follow these unless you correct them.

| ID | Assumption | Basis | Makes stale | To correct |
|---|---|---|---|---|
| A-1 | The agent ends the audio on Send, or on the 60 s auto-send, by yielding an empty `AudioEvent`. The input iterable stays open until Transcribe ends the response stream, and `stop()` resolves then with the transcript from r1/A-7. Ending the iterable instead makes the SDK close the socket at once (`socket.close(1000)`), and the final results are lost. E-1 puts this in AC5. (refines r1/A-6; doesn't replace it) | ADR-006 "For #29" (`docs/adr/0006-voice-transcription.md:89`), UX table (`:43`); `docs/architecture.md:74`; spike `spikes/s3-transcribe-browser/src/capture.ts:264-268` | nothing | `Decision r2/A-1: <your correction>` |
| A-2 | Capture follows the path the spike measured. The `AudioContext` is created at the native rate, at the top of `start()` before its first `await`, and `start()` always awaits `ctx.resume()` before `audioWorklet.addModule`. The worklet downsamples to 16 kHz. The agent doesn't use `new AudioContext({ sampleRate: 16000 })`, which worked on every browser but wasn't measured for accuracy. Safari and Firefox asking for the mic again after a reload is expected, and the agent doesn't handle it. | ADR-006 Consequences (`docs/adr/0006-voice-transcription.md:55-57`) and "For #29" (`:94-95`) | nothing | `Decision r2/A-2: <your correction>` |
| A-3 | The real-or-mock factory replaces `defaultTranscriber()` in `apps/web/src/voice/TranscriberContext.ts:21-23` (**required**: #28's hand-off, PR #154, and the file's own note at `:8`), and `ChatPage.tsx` doesn't change. So r1/Q-2's contingency for a `ChatPage.tsx` edit doesn't arise. `createContext(defaultTranscriber())` runs when the module loads (`:26`), and about a dozen jsdom `<ChatPage>` renders pass no Transcriber (#28 r1/A-2). The factory and the real Transcriber's constructor therefore touch no browser audio API, fetch no credentials, and don't import `@aws-sdk/client-transcribe-streaming`. All of that happens in `start()`, which keeps the SDK out of the entry chunk (r1/A-5). The agent also rewords the missing-config note, which says "isn't available yet". | #28 r1/A-2, A-3 (`spec/background/issue-28.md:65-66`); PR #154 hand-off (`spec/background/issue-154.md:38`, `:212`); r1/Q-2 (a) | `apps/web/src/voice/TranscriberContext.ts:5-8`<br>`apps/web/src/voice/TranscriberContext.test.ts:1`<br>`apps/web/src/voice/TranscriberContext.test.ts:12-22`<br>`apps/web/src/voice/VoiceInput.tsx:10`<br>`apps/web/README.md:20` | `Decision r2/A-3: <your correction>` |
| A-4 | `apps/web/build.test.ts` gains a check that the production bundle leaves out the `MockTranscriber`, by searching for `SAMPLE_TRANSCRIPT` (`apps/web/src/voice/MockTranscriber.ts:13`). It sits beside r1/A-5's lazy-load check. #28 checked this only by hand and left the test to #29. | PR #154 (`spec/background/issue-154.md:179`, `:212`); owned path `apps/web/build.test.ts` | nothing | `Decision r2/A-4: <your correction>` |

### Suggested edits to the issue

#### E-1: Say in AC5 how the audio ends, because the obvious way loses the transcript (ADR-006 "For #29")

Before:
```text
- [ ] Stream starts on record, ends on Send; waits for final results.
```
After:
```text
- [ ] Stream starts on record. On Send (or the 60 s auto-send), the audio ends with an empty `AudioEvent` while the input stays open, and `stop()` resolves when Transcribe ends the response stream with the final results (ADR-006 "For #29": ending the input iterable makes the SDK close the socket at once, and the finals are lost). A test with a fake Transcribe client shows the empty event is sent and the input isn't ended before the response stream ends.
```
- **Reply:** `Decision r2/E-1: accept` (or `reject`)

#### E-2: Make AC6 report what ADR-006 now asks of it: failed streams and Send→stream end

ADR-006's "Revisit if" now applies to #29's AC6 runs: "a browser shows more than one failed stream in #29's AC6 runs" (`docs/adr/0006-voice-transcription.md:59`). The "For #29" list asks for Send→stream end beside stop→final (`:93`).

Before:
```text
results in PR. A browser that misses 2 s is reported with its numbers and gets a follow-up issue; it doesn't block this PR.
```
After:
```text
results in PR, per browser: stop→final p95 (a final that arrives before Send counts as 0 ms), Send→stream end p95, and the number of failed streams (an error, the socket closing before the final results, or no final within 10 s of Send; ADR-006 Validation, #10 r1/Q-2). Runs hidden on purpose don't count. A browser that misses 2 s is reported with its numbers and gets a follow-up issue; it doesn't block this PR. A measured browser with more than one failed stream meets ADR-006's "Revisit if": it is reported first in the PR and gets a follow-up issue for the batch fallback, which this issue doesn't build.
```
- **Reply:** `Decision r2/E-2: accept` (or `reject`)

#### E-3: Fix AC3's line reference to `scripts/deploy-web.sh`, which moved by one line (#41)

Before:
```text
fails without it (`scripts/deploy-web.sh:76-100`)
```
After:
```text
fails without it (`scripts/deploy-web.sh:77-102`)
```
- **Reply:** `Decision r2/E-3: accept` (or `reject`)

#### E-4: Own the architecture lines that turn false once voice is live

`docs/architecture.md:5` lists voice among the parts that "aren't live yet", and `:70` reads "*(Planned: ADR-006 was accepted after spike S-3, #10; the voice UI ships with #29.)*". CLAUDE.md asks for a line a change makes false to be fixed in the same PR.

Before:
```text
- `docs/journal/**` (an entry for the choices this issue leaves to the agent)
```
After:
```text
- `docs/journal/**` (an entry for the choices this issue leaves to the agent)
- `docs/architecture.md` (the "Voice input" section's *Planned* note at `:70` and voice in the not-yet-live list at `:5`; a shared file, so call it out in the PR)
```
- **Reply:** `Decision r2/E-4: accept` (or `reject`)

### Reuse, dependencies and risks

- **Reuse:**
  - Move `spikes/s3-transcribe-browser/src/pcm-worklet.ts` (97 lines) into `apps/web/src/voice/transcribe/` (a suggestion; the folder is owned). Extract its downsample-and-encode step into a pure module and unit-test it (r1/A-6). The spike loads the worklet with Vite's `?worker&url` (`capture.ts:35`) and declares the three worklet globals locally (`pcm-worklet.ts:13-18`), so `apps/web/public/worklets/` isn't needed. ADR-006 recommends the move (`docs/adr/0006-voice-transcription.md:97`).
  - Move the start / stop / cancel flow of `spikes/s3-transcribe-browser/src/capture.ts` into the real Transcriber. It covers creating the context, resuming it and adding the worklet (`:168-183`), holding chunks until the socket opens, and the empty-event ending (`:264-268`). Adapt it to the four differences ADR-006 lists (`docs/adr/0006-voice-transcription.md:98-101`): credentials fetched inside `start()`, `stop()` resolving with the transcript and rejecting with a `TranscriberError`, no timeout of its own, and none of the instrumentation, which replaces the global `WebSocket`. The spike stays as it is.
  - Read the credentials by calling `fetchAuthSession()` from `aws-amplify/auth` and taking its `credentials`, through the voice-only credentials getter from r1/Q-1 (a). The spike's `spikes/s3-transcribe-browser/src/auth.ts:40-43` shows this call returning working Identity Pool credentials.
  - Implement `Transcriber`, `TranscriberCallbacks`, `TranscriberSession` and `TranscriberError` from `apps/web/src/voice/transcriber.ts:24-58`.
  - Import `MockTranscriber` from `apps/web/src/voice/MockTranscriber.ts` for the factory's dev-server branch.
  - Round 1's reuse pointers still hold: `apps/web/src/auth/` and `main.tsx` haven't changed since `9b2c17b`, and the `build.test.ts` lines they cite match.
- **Dependencies:** all of #29's blockers are now closed. #28 merged as PR #154 (`apps/web/src/voice/`); #10 as PR #225, which accepted ADR-006; #12 as PR #94. #100 is closed. Downstream, #36 is open and `status:backlog`.
- **Overlaps:** not rechecked against live GitHub. Since `9b2c17b`, no change on `main` touches `apps/web/src/auth/**`, `apps/web/src/main.tsx` or `apps/web/build.test.ts`.
- **Size:** about 800-1,100 changed lines excluding the lockfile, a little less than round 1's estimate, since the overlay, the missing-config state and a worklet to start from exist. There's also manual work: the AC4 check and AC6 runs on four browsers, two of them on Nick's phones. It fits one PR.
- **Sibling issues:**
  - #36 (open): "Voice uses the real Transcriber (#29)" is unchanged. Since 2026-10-05, #36 also holds a deferred real-browser pass of the recording overlay from #28. #29's AC6 runs exercise that overlay, but #29 doesn't take over the deferral.
  - #10 (closed): r1/Q-2's failure definition and r1/Q-4's clip mix carry into E-2.
  - #28 (closed): r1/A-2's context placement is now A-3.
- **Risks:**
  - The round-1 risk that the browser SDK might sign the HTTP/2 action is retired. The spike confirmed `/stream-transcription-websocket` and `StartStreamTranscriptionWebSocket` (`docs/adr/0006-voice-transcription.md:80`, `:90`), and AC4 still re-checks it on the shipped code.
  - The cold first stream on iOS took 3.6 s, 3.3 s of it in `getUserMedia` (`docs/adr/0006-voice-transcription.md:78`). `start()` resolves only after that, so the overlay's "starting" phase lasts that long on first use. That's expected, not a regression.

**Relied on:** `docs/adr/0006-voice-transcription.md` "Decision", "Consequences", "Validation (spike S-3, #10, …)" and "For #29"; `docs/architecture.md` "Voice input"; `docs/PRD.md` "FR-020" to "FR-024", "NFR-002", "NFR-006" and the "Safari AudioWorklet or Transcribe WebSocket quirks" risk row; `docs/adr/0005-auth.md` (Identity Pool, unchanged); issue #28 "Decisions and clarifications" r1/A-2, A-3 and PR #154's hand-off; issue #10 r1/Q-2 and r1/Q-4; this issue's "Decisions and clarifications" r1/Q-1, Q-2, A-1 to A-12.

<details>
<summary>What was checked</summary>

**Spec changes (`git diff 9b2c17b a6c8cca` on the direction documents)**

- `docs/adr/0006-voice-transcription.md`: Proposed → Accepted, with new Consequences, Validation and "For #29". **Matters.** Each item:
  - End of audio with an empty AudioEvent: AC5 is silent on it → E-1, A-1.
  - Signed action confirmed: AC4 holds as written, and r1/A-10 holds.
  - Stabilization off: r1/A-7 holds.
  - 1600-sample chunks: r1/A-6 holds.
  - Clip mix and Send→stream end: AC6 → E-2. The clip mix is already in AC6 ("as in #10").
  - Native-rate context and `resume()`: A-2.
  - Hidden page: Nick to decide → Q-1.
  - Code to move: Reuse.
  - Revisit rule tied to #29 AC6: E-2. The Non-goals line "No batch-transcription fallback" still holds, because a failing browser gets a follow-up issue.
  - Bundle 167.4 KiB minified, lazy, no Node shims: r1/A-5 holds.
  - Validation's dev-server method and "re-measures … on the shipped code" against r1/A-11: Q-2.
- `docs/architecture.md`: the voice section's "Planned" note and step 3 (empty AudioEvent). Step 3 agrees with A-1. The note turns false when #29 ships → E-4. The chat-turn sync markers don't matter.
- `docs/PRD.md`: the S-3 risk row is marked retired and says "the quirks it found are listed for #29". That agrees with the ADR. The FR-015, FR-030 and traceability changes are about chat and tools and don't touch voice. FR-020 to FR-024, NFR-002 and NFR-006 are unchanged.
- `docs/adr/README.md`: index status rows only. ADR-006 is now Accepted, as above.
- `docs/adr/0003-iac-layout.md` (2026-10-08, GitHub OIDC CI roles, #41): doesn't matter. It adds `sched-github-deploy` as a second identity for `deploy-web.sh`, and #29 deploys as `SchedDeployer` per r1/A-11. #41 also shifted `deploy-web.sh` by one line → E-3.
- `docs/adr/0007-chat-transport.md` (#104, #138, #160 amendments): chat retries and the `conversation` event. Doesn't matter: a transcript is posted through `useChat().send` like typed text (`ChatPage.tsx:97`), so it gets those behaviours without voice code.
- `docs/adr/0008-evaluation-strategy.md`, `docs/adr/0010-provider-neutral-llm-layer.md`: evals and the LLM layer. They don't matter.
- `docs/backlog.md`: evals rows and an edge. They don't matter.

**Round 1 items**

- r1/Q-1 (token path independent of the Identity Pool): still holds. `apps/web/src/auth/**` is unchanged since `9b2c17b`, and NFR-006 is unchanged.
- r1/Q-2 (#29 does the switch, in `voice/`): still holds. #28 put the selection in `voice/TranscriberContext.ts` (A-3), so no `ChatPage.tsx` change is needed.
- r1/A-1: still holds. The spike's `auth.ts:40-43` used `fetchAuthSession().credentials` with the Identity Pool and streamed.
- r1/A-2: still holds. No spec change touches the config rule.
- r1/A-3: still holds. #28 already built the disabled mic with a note (`VoiceInput.tsx:56-79`) and the dev-server mock. The rewording is in A-3.
- r1/A-4: still holds. The spike used `us-east-1`.
- r1/A-5: still holds. The ADR records the lazy chunk's size.
- r1/A-6: still holds. The spike's `src/` worklet with `?worker&url` is one of the two places it allows. A-1 and A-2 refine it.
- r1/A-7: still holds. The ADR's stabilization result agrees.
- r1/A-8: still holds. `transcriber.ts:12-19` and `useRecording.ts:9-11` match it.
- r1/A-9: still holds. Unmount cancels (`useRecording.ts:188-190`), and the spike saw the mic indicator go off after Send everywhere.
- r1/A-10: still holds. The ADR says "#29's role and AC4 work as written".
- r1/A-11: reopened → Q-2.
- r1/A-12: still holds. `apps/web/README.md:20` and `:29` are the same lines. The `deploy-web.sh` bundle check moved from `:107-111` to `:108-112`.
- r1/E-1 to E-7, as applied: still hold, except AC3's line reference → E-3.
- Deferral notes (`<!-- agent-pr-review:deferred`) on #29 since round 1: none. The 2026-10-05 note from #28 (`onLevel` optional) agrees with `transcriber.ts:20-21`.

**Code read at `a6c8cca`**

- `apps/web/src/voice/`: `transcriber.ts`, `TranscriberContext.ts` and its test, `MockTranscriber.ts`, `useRecording.ts`, and `VoiceInput.tsx` up to line 80.
- `apps/web/build.test.ts:55-80`, `apps/web/.env.example`, `apps/web/README.md:15-29`, `apps/web/vite.config.ts`.
- `scripts/deploy-web.sh:55-120`, and the same lines at `9b2c17b`, for the one-line shift.
- `git diff --stat 9b2c17b a6c8cca -- apps/web`: no change under `src/auth/`, `main.tsx` or `build.test.ts`.
- The spike: `package.json`, `vite.config.ts`, `tsconfig.json`, `src/auth.ts`, the head of `src/pcm-worklet.ts`, and greps of `src/capture.ts`.
- The 2026-10-08 journal entry.
- Background issues #10, #28, #36 and #154.

**Not checked**

- Live GitHub: open PRs, and comments added after the inputs were captured.
- Whether iOS's permission prompt fires `visibilitychange` (Q-1's edge treats "starting" as exempt either way).
- Whether `VITE_VOICE_TIMING` reaches the build through `deploy-web.sh`'s environment: read from the script's prefix-assignment form, not run.
- Spike results files beyond what ADR-006 quotes.

</details>

