# Garden Nursery — Claude Harness Contract

Steam Deck-first Godot cozy nursery sim. Ethan steers game direction and architecture.
Claude owns normal code work end to end: implement, verify, publish, monitor CI, repair
routine failures, and leave durable evidence. Use the `/ship` skill for any task that
should land on `main`.

## Steering Model

Ethan gives a prompt and direction; the harness does the rest with minimal human
intervention. `docs/VISION.md` is the durable product direction — read it when planning,
prioritizing, or breaking down work, and treat it as overriding older docs where they
conflict. `docs/creative-direction.md` is the creative authority for tone, writing, and
world; `docs/art-bible.md` for visuals. Proceed without approval for implementation
choices, tests, refactoring within scope, commits, pushes to `main`, monitoring, and
routine repair.

Stop and ask only for:

- Decisions that change the identity of the game.
- New paid services, credentials, or spending money.
- Publishing something publicly beyond this repo's CI artifacts.
- Destructive or irreversible operations.
- Ambiguity where the alternatives materially change the product.

## Delivery Contract

`main` is the trunk. A verified commit pushes straight to `main`; CI re-verifies
asynchronously with an automatic recovery boundary (optimistic delivery — no PR ceremony
for ordinary work).

- One coherent commit per task, conventional prefix (`feat:`/`fix:`/`chore:`/`docs:`/
  `test:`), message body ending with the exact trailer line `Harness-Managed: true`.
  Only commits carrying that trailer are eligible for automatic revert when CI fails
  while they are still the head of `main`.
- Stage files explicitly (`git add <paths>`); never `git add -A`.
- Before pushing: `git fetch origin main && git rebase origin/main`, run the checks
  below, then `git push origin HEAD:main`.
- After pushing: watch the Sanity workflow (`gh run list --commit <sha>` /
  `gh run watch <id>`). A task is complete only after CI passes. Report the commit hash,
  local verification, and CI result.
- For queued or background work, implement in an isolated worktree so Ethan's checkout
  stays untouched. In an interactive session on a clean checkout, working in place is fine.
- Use a PR only when Ethan asks to review first or the change trips the decision boundary.

## Verification

- `npm test` — the standard gate before every commit (data validation, simulation rule
  tests, repo shape checks). Dependency-light and fast.
- `npm run test:product` — required for any change under `godot/` (adds a real Godot
  headless import; needs `godot` 4.5.1 on PATH).
- `npm run godot:run` — launch the game locally; for gameplay-affecting changes, actually
  drive the affected flow, don't stop at headless checks.
- `npm run export:steamdeck` — local Steam Deck/Linux debug export; CI uploads the
  `garden-nursery-steamdeck-debug` artifact on every push to `main`, which is the
  playtest surface.
- Add checks to `scripts/agent-check.mjs` and rules to the simulation tests when a new
  system becomes important enough that future agents must not casually break it.

## Multi-Agent Orchestration

- `/ship <issue number | task description | next>` — the full autonomous pipeline:
  scope → implement → multi-agent adversarial review → verify → publish → monitor.
- `.claude/workflows/ship-review.js` — the review gate: parallel skeptics per dimension
  (correctness, design-fit, scope, tests), each finding adversarially verified before it
  can block or ship.
- `.claude/agents/builder.md`, `.claude/agents/skeptic.md` — implementation and
  adversarial-review subagents.

GitHub Issues labeled `agent-ready` are the durable work queue (priority labels
`priority:critical|high|medium|low`, tie broken by lowest issue number; skip issues
labeled `agent-running`, `decision-needed`, or `blocked`). Local docs
(`docs/session-handoff.md`, `docs/issue-backlog.md`, `docs/roadmap.md`) provide context
but never override the live issue queue or this file.

## Product Guardrails

These are always-on constraints; the detailed direction lives in `docs/VISION.md`.

- Steam Deck first: controller-first interaction, readable at 1280x800, no hover-only or
  pointer-only core actions.
- The first screen stays the walkable, plant-forward nursery yard. Do not regress into
  dashboard-first development.
- Writing is load-bearing: warm, specific, observant — never generic cozy filler.
- Systems become visible and testable before they become deep.
- Update `docs/roadmap.md` when a system is added, redirected, or cut; append to
  `docs/decisions.md` when a decision changes how the project is built.
