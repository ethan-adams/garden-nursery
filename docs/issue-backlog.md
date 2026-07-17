# Issue Backlog

Use GitHub issue numbers when asking Claude to work autonomously.

Example:

```sh
cd /Users/ethanadams/dev/garden-nursery
claude
```

Then:

```text
/ship 51
```

Or let the harness claim the queue head on its own:

```text
/ship next
```

## Current Next Issue

As of 2026-07-16 the harness selects work by looping on `docs/VISION.md` (see
`docs/decisions.md`); the live GitHub queue is the durable record, this pointer is not.
Remaining 0.3 foundation issues: `#101` seeded week-close RNG, `#97` plant-instance
refactor, plus `#100` left open for Ethan's art-director refinement. (`#91` was listed
here long after the fix shipped — code is ground truth over this file.)

## Godot Vertical Slice 0.1

Goal: walkable Hush Arbor yard, in-world stations, market hints, plant stand, propagation, customer loop, week outcome, save/journal basics, and sanity checks.

Completed:

- `#5` Set up Godot project - https://github.com/ethan-adams/garden-nursery/issues/5
- `#6` Define starter region brief - https://github.com/ethan-adams/garden-nursery/issues/6
- `#7` Define core data model - https://github.com/ethan-adams/garden-nursery/issues/7
- `#8` Establish Steam Deck UX baseline - https://github.com/ethan-adams/garden-nursery/issues/8
- `#9` Prototype market-reading loop - https://github.com/ethan-adams/garden-nursery/issues/9
- `#10` Build first nursery stand scene - https://github.com/ethan-adams/garden-nursery/issues/10
- `#12` Add Godot CI sanity check - https://github.com/ethan-adams/garden-nursery/issues/12
- `#13` Create writing sample pack - https://github.com/ethan-adams/garden-nursery/issues/13
- `#26` Build walkable 2.5D nursery yard foundation - https://github.com/ethan-adams/garden-nursery/issues/26
- `#27` Add in-world interaction station framework - https://github.com/ethan-adams/garden-nursery/issues/27
- `#28` Move nursery loop into world station overlays - https://github.com/ethan-adams/garden-nursery/issues/28
- `#29` Rework Hush Arbor yard art direction and first-screen UX - https://github.com/ethan-adams/garden-nursery/issues/29
- `#30` Polish walkable yard camera, collision, and controller feel - https://github.com/ethan-adams/garden-nursery/issues/30
- `#31` Add sanity checks for walkable world scene - https://github.com/ethan-adams/garden-nursery/issues/31
- `#35` Expand Hush Arbor starter plant catalog to vertical-slice size - https://github.com/ethan-adams/garden-nursery/issues/35
- `#36` Add customer-specific recommendation outcomes - https://github.com/ethan-adams/garden-nursery/issues/36
- `#37` Add end-of-week ledger with relationship notes - https://github.com/ethan-adams/garden-nursery/issues/37
- `#38` Add save and load for vertical-slice state - https://github.com/ethan-adams/garden-nursery/issues/38
- `#39` Add discovery journal MVP - https://github.com/ethan-adams/garden-nursery/issues/39
- `#40` Add simulation rule tests for market and recommendation scoring - https://github.com/ethan-adams/garden-nursery/issues/40
- `#41` Cut Godot Vertical Slice 0.1 playtest build - https://github.com/ethan-adams/garden-nursery/issues/41

Open:

- None. Continue with `Playable Hush Arbor Alpha 0.2`.

## Playable Hush Arbor Alpha 0.2

Goal: make Hush Arbor a repeatable small nursery game with richer stock, care, weather, customer memory, onboarding, events, and production-readable yard assets.

Completed:

- `#42` Extract nursery simulation state from UI scenes - https://github.com/ethan-adams/garden-nursery/issues/42
- `#43` Build multi-tray propagation queue - https://github.com/ethan-adams/garden-nursery/issues/43
- `#44` Add plant care needs and climate-fit consequences - https://github.com/ethan-adams/garden-nursery/issues/44
- `#45` Add season and weather calendar for Hush Arbor - https://github.com/ethan-adams/garden-nursery/issues/45
- `#46` Add customer memory and returning relationship beats - https://github.com/ethan-adams/garden-nursery/issues/46
- `#47` Add inventory pricing and restock economy - https://github.com/ethan-adams/garden-nursery/issues/47
- `#48` Add yard onboarding flow - https://github.com/ethan-adams/garden-nursery/issues/48
- `#49` Add Hush Arbor seed-swap event loop - https://github.com/ethan-adams/garden-nursery/issues/49
- `#50` Replace placeholder station art with production-readable Hush Arbor assets - https://github.com/ethan-adams/garden-nursery/issues/50

Open:

- None. Continue with `Make It Real 0.3`.

## Make It Real 0.3

Goal: make what exists real, playable, and felt — honest economy, working export art, controller UI that fits 1280x800, writing that surfaces in play, and foundations for later systems. Scoped from the 2026-07-10 critical review; every issue carries code-level evidence and observable acceptance criteria.

- `#91` Fix the always-paying week outcome (free money bug) - https://github.com/ethan-adams/garden-nursery/issues/91
- `#92` Fix exported-build art rendering (import pipeline) - https://github.com/ethan-adams/garden-nursery/issues/92
- `#93` Give the week a real action economy - https://github.com/ethan-adams/garden-nursery/issues/93
- `#94` Plant stand UI fits 1280x800 with working controller focus - https://github.com/ethan-adams/garden-nursery/issues/94
- `#95` Surface the writing pack in play - https://github.com/ethan-adams/garden-nursery/issues/95
- `#96` Select a plant without selling it - https://github.com/ethan-adams/garden-nursery/issues/96
- `#97` Refactor: plant instances, region-clean rules, state/presentation split - https://github.com/ethan-adams/garden-nursery/issues/97
- `#98` Behavioral tests that exercise the actual game - https://github.com/ethan-adams/garden-nursery/issues/98
- `#99` Season calendar runs a full year - https://github.com/ethan-adams/garden-nursery/issues/99
- `#100` Replace placeholder art with a coherent free asset pass - https://github.com/ethan-adams/garden-nursery/issues/100
- `#101` Seed and persist week-close RNG - https://github.com/ethan-adams/garden-nursery/issues/101

## Retired Codex Backlog

The codex-era batches for `Nursery Systems Alpha 0.3` (`#51`–`#56`), `Living Hush Arbor Alpha 0.4` (`#57`–`#61`), `Multi-Region Campaign Alpha 0.5` (`#62`–`#66`), and `Production Beta 0.8` (`#67`–`#71`) were closed as not-planned on 2026-07-10: their acceptance criteria reduced to green CI, the self-grading pattern the vision reset retired. The ambitions survive in `docs/roadmap.md`'s Later Milestones section; when their time comes they get re-created from `docs/VISION.md` with observable, felt acceptance criteria.

## Labels

- `agent-ready`
- `godot`
- `steam-deck`
- `writing`
- `systems`
- `vertical-slice`
- `tooling`
- `design`
- `data`
