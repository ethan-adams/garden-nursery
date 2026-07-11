# Session Handoff

This file is the short "start here" note for a future Claude session. The full plan
lives in `docs/roadmap.md`; the executable issue index lives in `docs/issue-backlog.md`;
the workflow contract is the root `CLAUDE.md`.

## Current State

- Local repo: `/Users/ethanadams/dev/garden-nursery`
- GitHub repo: https://github.com/ethan-adams/garden-nursery
- Trunk: `main` (harness-managed commits push directly; CI auto-reverts failures)
- Godot baseline: `4.5.1.stable.official`
- Product path: Godot project under `godot/`
- Archived sketch: `browser-prototype/`
- Current phase: build `Make It Real 0.3` (issues `#91`–`#101`; the codex-era backlog `#51`–`#71` is closed as not-planned)
- Current priority: make the existing game honest and felt — fix the exploitable economy and broken export art first (`#91`, `#92`).
- Read `docs/VISION.md` before planning anything; it was reset 2026-07-10 with Ethan's answers from the vision Q&A.

## What Exists

- `godot/scenes/main/main.tscn` loads the walkable yard scene.
- `godot/scenes/nursery/nursery_yard.tscn` has the Hush Arbor yard art, player, camera, and interactive stations.
- `godot/scenes/nursery/nursery_stand.tscn` contains the playable market/recommendation/propagation/week loop as station overlays.
- JSON catalogs live under `godot/data/`.
- Current content size: 16 plants, 3 customers, 4 market signals, and 3 week outcomes.
- `npm test` and `npm run test:product` are the standard local checks.
- GitHub milestones cover the end-to-end path from Vertical Slice 0.1 through Production Beta 0.8.

## Start Here

```sh
cd /Users/ethanadams/dev/garden-nursery
claude
```

Best next prompt:

```text
/ship next
```

Recommended immediate sequence:

1. `#91` Fix the always-paying week outcome (free money bug).
2. `#92` Fix exported-build art rendering (import pipeline).
3. `#93` Give the week a real action economy.

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

Local export currently requires Godot 4.5.1 Linux export templates installed on the Mac.
CI installs templates automatically and uploads the Steam Deck debug artifact.

## Key Docs

- `CLAUDE.md` - workflow contract and repo rules.
- `docs/VISION.md` - durable product direction.
- `docs/roadmap.md` - end-to-end product roadmap.
- `docs/issue-backlog.md` - issue-backed task index.
- `docs/creative-direction.md` - game identity and writing pillars.
- `docs/starter-region-brief.md` - Hush Arbor region.
- `docs/steam-deck-ux-baseline.md` - Steam Deck UX requirements.
- `docs/art-bible.md` - production visual target.
- `docs/visual-development-pipeline.md` - visual asset workflow.
- `docs/testing-and-builds.md` - Mac, CI, and Steam Deck test path.
- `docs/decisions.md` - lightweight decision log.

## Important Direction

Keep new systems anchored in the walkable yard and station overlays. The player should
feel like they are walking up to nursery objects and doing nursery work there.

Keep all ordinary work issue-backed and delivered through the `/ship` pipeline: one
coherent `Harness-Managed: true` commit, verified with `npm test` (and
`npm run test:product` for Godot changes), pushed to `main`, and watched through CI.
