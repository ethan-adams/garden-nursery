# Garden Nursery — Claude Harness Contract

Steam Deck-first Godot cozy nursery sim. Ethan steers game direction and architecture.
Claude owns normal code work end to end: implement, verify, publish, and leave durable
evidence. This repo runs **fast-ship**: optimize for iteration speed over ceremony, and
tolerate a temporarily red `main` — breaking main here is an acceptable cost of moving
fast, not an incident. For ordinary work, commit → verify locally → push → keep moving.
Reserve the full `/ship` pipeline (with its multi-agent review gate) for genuinely risky,
large, or architectural changes, or when Ethan asks for it.

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

`main` is the trunk. A locally-verified commit pushes straight to `main`; CI re-verifies
asynchronously with an automatic recovery boundary (optimistic delivery — no PR ceremony
for ordinary work).

- One coherent commit per task, conventional prefix (`feat:`/`fix:`/`chore:`/`docs:`/
  `test:`), message body ending with the exact trailer line `Harness-Managed: true`.
  Only commits carrying that trailer are eligible for automatic revert when CI fails
  while they are still the head of `main`.
- Stage files explicitly (`git add <paths>`); never `git add -A`.
- Before pushing: `git fetch origin main && git rebase origin/main`, run the local gates
  below, then `git push origin HEAD:main`.
- **Don't block waiting on CI.** After pushing, a task is complete once it's locally
  verified and pushed — report the commit hash and local verification, and move on to the
  next thing. CI still re-verifies async and auto-reverts a red head; if that happens,
  pick it up on the next turn or fix forward when convenient, rather than watching a run
  to completion. Do a quick `gh run list --commit <sha>` glance only when the change is
  export- or CI-config-adjacent (the classes CI catches that local gates don't).
- For queued or background work, implement in an isolated worktree so Ethan's checkout
  stays untouched. In an interactive session on a clean checkout, working in place is fine.
- Use a PR only when Ethan asks to review first or the change trips the decision boundary.

## Verification

These fast local gates are deliberately kept under fast-ship — they're cheap and they're
what let the harness ship unsupervised, so relaxing ceremony never means skipping them.
Run the gate that fits the change; don't gold-plate a docs or data typo.

- `npm test` — the standard gate before every commit (data validation, simulation rule
  tests, repo shape checks). Dependency-light and fast.
- `npm run test:product` — for any change under `godot/` (adds a real Godot headless
  import; needs `godot` 4.5.1 on PATH).
- `npm run godot:run` — launch the game locally; for gameplay-affecting changes, actually
  drive the affected flow, don't stop at headless checks.
- `npm run godot:screens` — the self-playtest capture; skim the four shots for any
  UI/visual change (this is Ethan's per-ship eyes — keep using it and put a strip in the
  report). `npm run export:steamdeck` — run locally only when the change touches export,
  boot-time resources, or CI config; otherwise CI covers it.
- `scripts/agent-check.mjs` holds the repo-shape assertions. Add a guard when a new system
  must not be casually broken — but these are a convenience, not a wall: if an assertion
  fights an intentional change, update or delete it in the same commit rather than working
  around it.

## Multi-Agent Orchestration (opt-in under fast-ship)

The multi-agent review gate is powerful but expensive (a fleet of agents and a lot of
tokens per run), and in practice the cheap local gates above catch the problems that
actually break things. So it is **not** run on every ship. Reach for it when the change is
genuinely risky, large, or architectural — new simulation systems, save-format changes,
broad refactors — or whenever Ethan asks. Ordinary work skips straight to
commit → verify → push.

- `/ship <issue number | task description | next>` — the full pipeline when you do want it:
  scope → implement → multi-agent adversarial review → verify → publish.
- `.claude/workflows/ship-review.js` — the review gate: parallel skeptics per dimension
  (correctness, design-fit, scope, tests), each finding adversarially verified.
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
