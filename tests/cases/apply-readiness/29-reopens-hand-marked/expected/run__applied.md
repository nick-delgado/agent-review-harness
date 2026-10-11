<!-- agent-pr-review:readiness-applied round=2 -->
## Readiness answers applied (round 2)

Only `Decision r2/<ID>: ...` lines count; other replies are not applied.

**Applied:**
- E-4: Own the architecture lines that turn false once voice is live
- Q-1: answered, (a) An error on every browser: when `document.visibilityState` becomes `hidden` while recording, the real Transcriber calls `onError` with a `failed` `TranscriberError`, stops the mic and closes the stream. #28's overlay then shows the FR-024 error with Record again / Type instead and calls `cancel()` (`apps/web/src/voice/useRecording.ts:147-149`). No interface or overlay change. Scope: within the issue.
- Q-2: answered, (a) An opt-in build flag. The timing record (`performance.now()` at Send or the 60 s auto-send, at the last final result, and at the end of the stream) and a way to export it are compiled in only when `VITE_VOICE_TIMING=1` is set at build time. The AC4 and AC6 runs use an ephemeral env published with `VITE_VOICE_TIMING=1 scripts/deploy-web.sh <name>`: the script's build inherits the shell's environment, so it needs no change. Phones load the env over CloudFront HTTPS, so no certificates are needed. `dev` and other deploys leave the flag unset, and `apps/web/build.test.ts` shows a build without it contains no timing code. Scope: within the issue (`env.d.ts` and `build.test.ts` are owned).
- r1/A-11: already marked superseded

**Not applied:**
- E-1 (Say in AC5 how the audio ends, because the obvious way loses the transcript (ADR-006 "For #29")): its Before text is not in the description any more; not applied
- E-2 (Make AC6 report what ADR-006 now asks of it: failed streams and Send→stream end): its Before text is not in the description any more; not applied
- E-3 (Fix AC3's line reference to `scripts/deploy-web.sh`, which moved by one line (#41)): its Before text is not in the description any more; not applied

**Still open** (each needs its own `Decision` line):
- nothing
