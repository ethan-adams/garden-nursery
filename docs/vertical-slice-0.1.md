# Godot Vertical Slice 0.1

## Goal

Prove the core Garden Nursery loop as a Steam Deck-first Godot game, not as a browser sketch.

The slice should answer one question:

Is it fun and emotionally resonant to learn a place, read people, grow stock, and make recommendations?

## Scope

Build a small playable loop in one starter region:

1. Read local market hints.
2. Choose or prepare stock.
3. Serve a few customers.
4. Advance the week.
5. See outcomes in cash, reputation, stock, relationship notes, and market learning.

## Non-Goals

- No multiplayer.
- No full country map.
- No complete season simulation.
- No final art.
- No complete writing pass.
- No Steam integration yet.

## Required Slice Elements

- Godot 4.5.x project.
- Steam Deck-friendly 1280x800 baseline.
- Controller navigable UI.
- Steam Deck UX baseline from `docs/steam-deck-ux-baseline.md`.
- Starter region placeholder name and climate hooks.
- Small roadside nursery stand scene.
- Plant inventory with 12-20 plant/crop analogues.
- 3-4 recurring customer archetypes.
- Market signal board or equivalent.
- One propagation bench or simplified grow-stock action.
- End-of-week summary.

## Success Criteria

- The loop is playable with keyboard and controller-friendly focus structure.
- Text is readable at 1280x800.
- The player can infer at least one market trend from in-world signals.
- The player can make at least one recommendation or sale based on that trend.
- The week outcome reflects the player's choice.
- The project can run through the repo harness.

## First Region Requirements

The first region should be welcoming, readable, and forgiving.

It should still have:

- Distinct ecology.
- Local customs.
- Mild magical realism.
- Early market pressure.
- Characters with real desires and contradictions.

## Writing Requirements

Even placeholder writing should follow the creative direction:

- Warm.
- Specific.
- Lightly funny where appropriate.
- Hopeful without lying.
- No generic cozy filler.

## Issue Sequence

- `#5` Set up Godot project.
- `#6` Define starter region brief.
- `#8` Establish Steam Deck UX baseline.
- `#7` Define core data model.
- `#10` Build first nursery stand scene.
- `#9` Prototype market-reading loop.
- `#13` Create writing sample pack.
- `#12` Add Godot CI sanity check.
