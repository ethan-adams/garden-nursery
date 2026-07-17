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
- Progress (2026-07-11): the felt gate is nearly clear. Closed: `#91` free-money, `#92` export art, `#93` action economy, `#94` stand vertical fit, `#95` writing-pack surfacing, `#96` select-without-selling, `#98` behavioral/screenshot harness, `#103` stand horizontal overflow guard. `#100` pixel-art identity (Kenney Tiny Farm CC0) shipped a first pass and is **left open** for Ethan's art-director refinement (ledger/journal props are weak — see the issue comment and `docs/decisions.md` 2026-07-11).
- Visual identity is now **cozy pixel art** — `docs/decisions.md` 2026-07-11 supersedes the art-bible's painterly pillar for the current gate.
- Progress (2026-07-16): `#99` full-year calendar shipped — 24-week wrapping year, season-tagged signals, four community events, restrained magic surfacing at the longest night. Work selection now loops on `docs/VISION.md` via Ethan's generalized harness (`~/dev/harness`); issues are the durable record, not the driver (see `docs/decisions.md` 2026-07-16).
- Current priority: `#101` seeded week-close RNG, `#97` plant instances/region-clean refactor, then scope `0.4 A Living Day`; `#100` stays open for Ethan's art-director refinement.
- Read `docs/VISION.md` before planning anything; it was reset 2026-07-10 with Ethan's answers from the vision Q&A.

## What Exists

- `godot/scenes/main/main.tscn` loads the walkable yard scene.
- `godot/scenes/nursery/nursery_yard.tscn` has the Hush Arbor yard art, player, camera, and interactive stations.
- `godot/scenes/nursery/nursery_stand.tscn` contains the playable market/recommendation/propagation/week loop as station overlays.
- JSON catalogs live under `godot/data/`.
- Current content size: 16 plants, 3 customers, 12 season-tagged market signals, 7 week outcomes, a 24-week year, and 4 community events.
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

1. `#100` Refine the pixel-art pass with Ethan's eye (better ledger/journal props, denser composition) — visual identity is his call.
2. `#99` / `#97` / `#101` Foundation: full-year calendar, plant-instance refactor, seeded week-close RNG.

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
