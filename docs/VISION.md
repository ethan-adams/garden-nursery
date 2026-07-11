# Garden Nursery — Vision

Seeded 2026-07-10 during the migration from the codex harness to the Claude harness,
consolidating direction that previously lived in `AGENTS.md` and scattered docs. This is
the durable steering document for the repo: when work is planned, broken down, or
prioritized, it defers to this file, and where older docs conflict with it, this file
wins and the older doc should be updated. A vision Q&A session with Ethan is pending;
expect this file to be revised with dated decisions from that session.

## What This Game Is

A Steam Deck-first, single-player Godot 4.x cozy systems narrative game about starting a
small nursery in a fictional country, learning local plants and markets, and becoming
part of a place through patience, care, and attention.

It is not "Stardew but plants" and not just retail. The playable fantasy is learning a
place through nursery work: propagation, customer care, market reading, seasonal
adaptation, plant discovery, and region-specific constraints. Writing is load-bearing,
magic is restrained magical realism, and the tone is gentle and hopeful but not naive.

`docs/creative-direction.md` is the creative authority (identity, writing pillars,
regions, magic, character design). `docs/roadmap.md` holds the milestone ladder from
Vertical Slice 0.1 through Production Beta 0.8.

## How Ethan Works

Ethan vibes this project out between other activities: he gives prompts and
architectural steering; Claude owns execution end to end. Two modes, chosen at will per
session:

- **Co-pilot** — Ethan stays in the loop for micro product-design corrections; short
  prompts, fast small ships.
- **Autonomous** — plan together up front, then run the whole batch (including
  overnight) without intervention and report evidence at the end. The plan is the
  contract; the agent drains it and reports evidence.

Direction he gives should be captured durably here (dated), so he never has to repeat
it. Later, direction gets broken into issue-backed work without re-asking.

## Economics

No monthly costs. Free tiers and local compute by default (local Godot, GitHub free CI,
local asset generation). Propose a paid option only when it is architecturally much
better, very cheap, and explicitly justified to Ethan before adoption.

## Product Pillars (carried forward 2026-07-10)

- **Playable first.** Bold playable drafts over long planning pauses. Every milestone
  leaves the game more playable than it found it. Small simulations with expressive text
  beat empty UI scaffolding.
- **Steam Deck first.** 1280x800 readability, controller-first, fast suspend/resume,
  satisfying 10–20 minute sessions. The old browser prototype is archived; Godot under
  `godot/` is the product.
- **Market reading is a core pillar.** Demand shifts by region, season, weather, events,
  and taste; information arrives through the world (customers, gossip, boards, weather
  signs), not a spreadsheet. Paying attention should feel powerful.
- **Regional specificity.** Plants, customers, customs, and market taste teach the
  player where they are. Strategies must not transfer cleanly between regions.
- **Writing bar.** Warm, funny when it can be, specific, observant, hopeful without
  lying. No generic cozy wholesomeness, no clean villains, no lore dumps, no player
  flattery.
- **Restrained magic.** Magical realism that reveals relationships and care; magic grows
  beside ordinary herbs and stays local, not a power system.
- **Visual taste.** Warm, tactile, plant-forward, region-aware; cozy botanical
  illustration, not default pixel art or generic fantasy farming. `docs/art-bible.md`
  holds the acceptance bar.
- **Learnable code.** Keep code readable enough that Ethan can learn game programming
  from it.

## Where This Is Going

The milestone ladder in `docs/roadmap.md`: 0.1 vertical slice (done) → 0.2 Hush Arbor
alpha (issues closed; quality unproven) → 0.3 systemic nursery → 0.4 living region →
0.5 multi-region campaign → 0.8 production beta. GitHub issues are the executable queue;
milestones are the narrative of why the issues exist.

## Open Questions (to resolve in vision sessions with Ethan)

- What does "done enough to be fun" mean before adding more systems? The slice has many
  systems and no recorded human playtest verdict.
- Who is this game for beyond Ethan — is shipping on Steam a real goal with a date, or a
  directional fiction that keeps quality honest?
- Art production: the art bible's bar is far beyond current placeholder SVGs and there is
  no artist. What is the realistic path (AI-generated, purchased packs, commissioned,
  Ethan learns)?
- Writing production: who writes the load-bearing writing, and how is its quality judged?
- How much simulation depth vs. narrative warmth — where does the next year of effort go
  if it can only deepen one?
