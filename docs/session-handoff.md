# Session Handoff

## Current State

- Local repo: `/Users/ethanadams/dev/garden-nursery`
- GitHub repo: https://github.com/ethan-adams/garden-nursery
- Current branch: `main`, synced with `origin/main`
- Open issues: none
- Open PRs: none
- Godot baseline: `4.5.1.stable.official`
- Current project phase: Godot Vertical Slice 0.1 is scaffolded and ready for deeper playable systems.
- Current priority: pivot from flat dashboard prototype to a walkable 2.5D nursery yard.
- Current quality correction: do not stack more systems onto a lifeless blockout. Prioritize yard composition, station readability, and first-screen UX before deeper mechanics.

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

- PR #25: `feat: add propagation bench loop`
  - Added plant-specific propagation cost, method, time, yield, and success chance.
  - Added one active bench tray that progresses on week advance and feeds successful starts back into inventory.

## Start Here

From a terminal:

```sh
cd /Users/ethanadams/dev/garden-nursery
cdsp
```

Good next prompt:

```text
Work issue #26. Follow AGENTS.md.
```

Current walkable-yard issue batch:

- `#26` Build walkable 2.5D nursery yard foundation
- `#27` Add in-world interaction station framework
- `#28` Move nursery loop into world station overlays
- `#29` Rework Hush Arbor yard art direction and first-screen UX
- `#30` Polish walkable yard camera, collision, and controller feel
- `#31` Add sanity checks for walkable world scene

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
  - Start one plant-specific propagation tray.
  - Update cash and reputation.
  - Advance week and show outcome text.
- Browser prototype is archived under `browser-prototype/` and should not drive product decisions.

## What Is Missing

- Walkable 2.5D nursery yard and in-world stations.
- Stronger first-screen art direction and UX validation beyond automated smoke checks.
- Customer-specific sold/unsold/discovery outcomes tied to budget, taste, garden constraints, and relationship memory.
- Expanded Hush Arbor plant catalog: vertical slice target is 12-20 plants; current Godot catalog has 6.
- Simulation tests for market scoring and customer outcomes after logic is split out of the scene script.
- Manual 1280x800 layout/focus pass and Steam Deck playtest pass.
- Hybrid bench design decisions before rebuilding that mechanic in Godot.
- Save/load state.

## Recommended Next Issue Batch

1. `#26` Build walkable 2.5D nursery yard foundation
2. `#27` Add in-world interaction station framework
3. `#28` Move nursery loop into world station overlays
4. `#29` Rework Hush Arbor yard art direction and first-screen UX
5. `#30` Polish walkable yard camera, collision, and controller feel
6. `#31` Add sanity checks for walkable world scene

## Important Direction

This is a Steam Deck-first Godot cozy nursery sim. The product should be harder to break now: keep changes issue-backed, run the standard checks, open PRs, wait for CI, and squash-merge when green.

Prioritize the walkable nursery body before adding more dashboard depth. The first screen needs care: composed space, readable silhouettes, tactile local details, and no visible debug copy. Keep writing and world details specific to Hush Arbor and avoid generic cozy filler.
