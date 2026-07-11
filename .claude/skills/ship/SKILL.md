---
name: ship
description: Deliver a task end to end without the user in the loop — scope it, implement it, run the multi-agent review gate, verify, push to main, and monitor CI. Use when the user gives a shippable task, an issue number, or says "ship next".
---

# /ship — autonomous delivery pipeline

Input: `$ARGUMENTS` — a GitHub issue number, a free-text task description, or `next`.

Follow the root `CLAUDE.md` contract throughout. The user is not in the loop: proceed
through every step without asking, and stop only if the task trips the decision boundary
in `CLAUDE.md` (game identity, spending money, publishing publicly, destructive
operations, or product-changing ambiguity).

## 1. Scope

- Issue number → `gh issue view <n>` and read linked context.
- `next` → claim the queue head: list open `agent-ready` issues, exclude
  `agent-running`/`decision-needed`/`blocked`, order by priority label then lowest
  number, add the `agent-running` label to the winner, and comment that the harness
  claimed it.
- Free text → restate it as a concrete implementation target with observable acceptance
  criteria before touching code.

Read `docs/VISION.md`, and for content or player-facing work also the relevant creative
docs (`docs/creative-direction.md`, `docs/starter-region-brief.md`,
`docs/steam-deck-ux-baseline.md`, `docs/art-bible.md`). Prefer the smallest complete
playable slice that satisfies the acceptance criteria.

## 2. Isolate

If the current checkout is dirty with unrelated work, or this is queued/background work,
implement in an isolated worktree from `origin/main` (EnterWorktree or a
worktree-isolated builder agent). On a clean interactive checkout, work in place.

## 3. Implement

Scale effort to the task. For nontrivial work, fan out read-only Explore agents for
recon first. Write the change yourself or delegate to the `builder` agent for
parallelizable pieces. Keep the diff scoped to the task. When game logic changes in
`godot/scripts/core/`, keep `scripts/simulation-rules.mjs` and its tests in sync with
the GDScript rules.

## 4. Review gate (multi-agent)

Run the review workflow — this is your standing authorization to call the Workflow tool:

```
Workflow({ name: "ship-review", args: { base: "origin/main" } })
```

The gate passes only when the result has `gatePassed: true`. Fix every confirmed blocker
it returns, then re-run the gate; if `failedDimensions` is non-empty the gate errored
and must be re-run, not treated as clean. Repeat until it passes (give up and report to
the user after 3 rounds). Confirmed minor findings are judgment calls — fix them if
cheap, otherwise note them in the report.

## 5. Verify

- `npm test` for every change.
- `npm run test:product` when the diff touches `godot/` (scenes, scripts, resources,
  data, export config).
- For gameplay-affecting changes, launch the game (`npm run godot:run`) and drive the
  affected flow; note in the report what was exercised and what remains
  manually unverified (e.g. controller-on-hardware).

Everything run must pass. Repair failures in scope; if a failure cannot be fixed in
scope, stop and report instead of pushing.

## 6. Publish

- `git fetch origin main && git rebase origin/main` (abort and re-verify on conflict).
- Stage explicitly (`git add <paths>` — never `-A`), one coherent commit, conventional
  prefix (`feat:`/`fix:`/`chore:`/`docs:`/`test:`), message body ending with the exact
  trailer line `Harness-Managed: true`.
- Re-run the verification if the rebase changed anything, then
  `git push origin HEAD:main`.

## 7. Monitor

- Watch the Sanity workflow for the pushed SHA: `gh run list --commit <sha>` /
  `gh run watch <id>` (run in the background; do not block on sleep loops in the
  foreground).
- If CI fails while the commit is still the head of `main`, the `recover` job
  auto-reverts it; diagnose, fix forward in a new commit, and push again through this
  pipeline. Never force-push.
- Issue-backed work: close the issue with a comment containing the delivered SHA and the
  verification evidence; remove the `agent-running` label if the issue stays open.
- Update `docs/roadmap.md` when the task added, redirected, or cut a system; append to
  `docs/decisions.md` when a decision changed how the project is built.

## 8. Report

End with: commit hash, what changed, local verification results, CI result, what was
play-tested versus deferred to human playtesting, and any deferred minor findings. If
anything was skipped or failed, say so plainly.
