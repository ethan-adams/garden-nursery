# Session Handoff

## Current State

- Local repo: `/Users/ethanadams/dev/garden-nursery`
- GitHub repo: https://github.com/ethan-adams/garden-nursery
- Current branch: `main`, synced with `origin/main`
- Open issues: none
- Open PRs: none
- Godot baseline: `4.5.1.stable.official`
- Current project phase: Godot Vertical Slice 0.1 is scaffolded and ready for deeper playable systems.

## Latest Merged Work

- PR #22: `feat: add Godot nursery market loop`
  - Added the first Godot roadside nursery stand scene.
  - Added JSON catalogs for Hush Arbor plants, customers, region signals/outcomes, and dialogue.
  - Added a playable market-reading/recommendation/week-outcome loop.

- PR #23: `chore: harden product test harness`
  - Moved disposable browser sketch to `browser-prototype/`.
  - Added `npm test`, `npm run test:product`, and Steam Deck/Linux export workflow.
  - Added CI Steam Deck debug export artifact: `garden-nursery-steamdeck-debug`.
  - Added `docs/testing-and-builds.md`, `docs/decisions.md`, and `docs/claude-brief-review.md`.

## Start Here

From a terminal:

```sh
cd /Users/ethanadams/dev/garden-nursery
cdsp
```

Good next prompt:

```text
Create the next issue batch for propagation, customer outcomes, plant catalog expansion, and Steam Deck playtest polish. Follow AGENTS.md.
```

Or, to start implementation immediately:

```text
Implement the propagation bench loop as the next vertical-slice system. Follow AGENTS.md.
```

## Standard Checks

Run before committing ordinary changes:

```sh
npm test
```

Run before pushing Godot scene/script/resource changes:

```sh
npm run test:product
```

Run locally in Godot:

```sh
npm run godot:run
```

Export Steam Deck/Linux debug build:

```sh
npm run export:steamdeck
```

Local export currently requires Godot 4.5.1 Linux export templates installed on the Mac. CI installs templates automatically and uploads the Steam Deck debug artifact.

## Key Docs

- `AGENTS.md` - workflow and repo rules.
- `docs/testing-and-builds.md` - Mac, CI, and Steam Deck test path.
- `docs/roadmap.md` - current project memory rail.
- `docs/vertical-slice-0.1.md` - vertical slice target.
- `docs/starter-region-brief.md` - Hush Arbor region.
- `docs/writing-sample-pack.md` - current writing tone samples.
- `docs/godot-project-structure.md` - Godot/data layout and CI approach.
- `docs/claude-brief-review.md` - what to use and ignore from the Claude brief.
- `docs/decisions.md` - lightweight decision log.

## What Exists

- Godot project in `godot/`.
- Main scene loads `godot/scenes/nursery/nursery_stand.tscn`.
- Data catalogs live under `godot/data/`.
- Current playable loop:
  - Read Hush Arbor market signals.
  - See recurring customer hints.
  - Recommend a plant from inventory.
  - Update cash and reputation.
  - Advance week and show outcome text.
- Browser prototype is archived under `browser-prototype/` and should not drive product decisions.

## What Is Missing

- Propagation bench loop with time, cost, failure chance, and inventory arrival.
- Customer-specific sold/unsold/discovery outcomes tied to budget, taste, garden constraints, and relationship memory.
- Expanded Hush Arbor plant catalog: vertical slice target is 12-20 plants; current Godot catalog has 6.
- Simulation tests for market scoring and customer outcomes after logic is split out of the scene script.
- Manual 1280x800 layout/focus pass and Steam Deck playtest pass.
- Hybrid bench design decisions before rebuilding that mechanic in Godot.
- Save/load state.

## Recommended Next Issue Batch

1. `feat: Add propagation bench loop`
2. `feat: Add customer-specific recommendation outcomes`
3. `feat: Expand Hush Arbor starter plant catalog`
4. `test: Add simulation checks for market scoring`
5. `fix: Polish nursery stand 1280x800 focus and layout`
6. `docs: Decide hybrid bench rules`

## Important Direction

This is a Steam Deck-first Godot cozy nursery sim. The product should be harder to break now: keep changes issue-backed, run the standard checks, open PRs, wait for CI, and squash-merge when green.

Prioritize playable systems over docs-only work unless the docs unblock architecture. Keep writing specific to Hush Arbor and avoid generic cozy filler.
