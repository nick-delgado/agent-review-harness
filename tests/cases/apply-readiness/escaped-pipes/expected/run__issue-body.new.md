## Goal
Parse flags.

## Owned paths
- `src/flags.ts`

## Decisions and clarifications

Settled before work started, in answer to readiness reviews: the owner's answers, and the assumptions the owner let stand. Coding agents and PR reviewers treat these as part of the spec.

- **r1/A-2** (settled against `aaaaaaa`): Output is joined with ` | ` → corrected: use a comma, not | ([answer](https://github.test/c/2))
- **r1, assumed** (as of `aaaaaaa`):
  - A-1: The agent accepts `--mode a|b` and rejects anything else

