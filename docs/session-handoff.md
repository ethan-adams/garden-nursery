# Session Handoff

This file is the short "start here" note for a future Codex session. The full plan lives in `docs/roadmap.md`; the executable issue index lives in `docs/issue-backlog.md`.

## Current State

- Local repo: `/Users/ethanadams/dev/garden-nursery`
- GitHub repo: https://github.com/ethan-adams/garden-nursery
- Normal starting branch: `main`
- Godot baseline: `4.5.1.stable.official`
- Product path: Godot project under `godot/`
- Archived sketch: `browser-prototype/`
- Current phase: build `Playable Hush Arbor Alpha 0.2`
- Current priority: make the station-based yard loop repeatable across several weeks.

## What Exists

- `godot/scenes/main/main.tscn` loads the walkable yard scene.
- `godot/scenes/nursery/nursery_yard.tscn` has the Hush Arbor yard art, player, camera, and interactive stations.
- `godot/scenes/nursery/nursery_stand.tscn` contains the playable market/recommendation/propagation/week loop as station overlays.
- JSON catalogs live under `godot/data/`.
- Current content size: 16 plants, 3 customers, 4 market signals, and 3 week outcomes.
- `npm test` and `npm run test:product` are the standard local checks.
- GitHub milestones now cover the end-to-end path from Vertical Slice 0.1 through Production Beta 0.8.

## Start Here

From a terminal:

```sh
cd /Users/ethanadams/dev/garden-nursery
cdsp
```

Best next prompt:

```text
Work issue #47. Follow AGENTS.md.
```

Recommended immediate sequence:

1. `#47` Add inventory pricing and restock economy.
2. `#48` Add yard onboarding flow.
3. `#49` Add Hush Arbor seed-swap event loop.
4. `#50` Replace placeholder station art with production-readable Hush Arbor assets.

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

Export a Steam Deck/Linux debug build:

```sh
npm run export:steamdeck
```

Local export currently requires Godot 4.5.1 Linux export templates installed on the Mac. CI installs templates automatically and uploads the Steam Deck debug artifact.

## Key Docs

- `AGENTS.md` - workflow and repo rules.
- `docs/roadmap.md` - end-to-end product roadmap.
- `docs/issue-backlog.md` - issue-backed task index.
- `docs/vertical-slice-0.1.md` - first playable Godot target.
- `docs/creative-direction.md` - game identity and writing pillars.
- `docs/starter-region-brief.md` - Hush Arbor region.
- `docs/steam-deck-ux-baseline.md` - Steam Deck UX requirements.
- `docs/art-bible.md` - production visual target.
- `docs/visual-development-pipeline.md` - visual asset workflow.
- `docs/testing-and-builds.md` - Mac, CI, and Steam Deck test path.
- `docs/decisions.md` - lightweight decision log.

## Important Direction

Keep new systems anchored in the walkable yard and station overlays. The player should feel like they are walking up to nursery objects and doing nursery work there.

Keep all ordinary work issue-backed, branch-based, PR-first, and checked through `npm test`. Use `npm run test:product` for Godot scene/script/resource work.
