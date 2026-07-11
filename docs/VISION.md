# Garden Nursery — Vision

Seeded 2026-07-10 during the migration from the codex harness to the Claude harness;
revised the same day with decisions from the vision Q&A with Ethan. This is the durable
steering document for the repo: when work is planned, broken down, or prioritized, it
defers to this file, and where older docs conflict with it, this file wins and the older
doc should be updated.

## What This Game Is

A Steam Deck-first, single-player Godot 4.x cozy systems narrative game about starting a
small nursery in a fictional country, learning local plants and markets, and becoming
part of a place through patience, care, and attention.

It is not "Stardew but plants" and not just retail. The playable fantasy is learning a
place through nursery work: propagation, customer care, market reading, seasonal
adaptation, plant discovery, and region-specific constraints. Writing is load-bearing,
magic is restrained magical realism, and the tone is gentle and hopeful but not naive.

`docs/creative-direction.md` is the creative authority (identity, writing pillars,
regions, magic, character design). `docs/roadmap.md` holds the milestone ladder.

## Why This Project Exists (decided 2026-07-10)

In priority order:

1. **Ethan learning game development** — the code should stay readable enough to learn
   from, and the project should teach him how games get made.
2. **Making something that feels like a world** — a place with weather, people, and
   texture that the player can get a little lost in.
3. **Steam someday, revenue never** — the game targets Ethan's own Steam Deck first and
   an eventual Steam release is directional, but this is for fun, not money.

**The player-zero rule (decided 2026-07-10):** Ethan's continued interest is a design
constraint, not a nice-to-have. Whatever makes the game playable and interesting comes
first, because if the game bores him, development stops. Systemic completeness never
outranks felt experience. This retires the codex-era habit of measuring progress by
issues closed.

## The Minute-to-Minute Fantasy (decided 2026-07-10)

Fifteen minutes on the Deck should engage the mind on three horizons at once:

- **Today**: what needs care right now — watering, trays, a customer, a task with a
  deadline.
- **This season**: what will be good for the season; reading signals and placing bets.
- **The long arc**: medium- and long-term plans — what the nursery is becoming.

Around that thinking, the player should get a little lost in the world and feel part of
something bigger than the shop. Systems that don't feed one of those three horizons or
that world-feeling are flavor, not foundation.

## State of the Game (assessed 2026-07-10)

Ethan has played the current build and his verdict is the honest baseline: the UI is
basic, nothing feels real or interesting, the graphics are bad, and the systems feel
dead. The July 2026 critical review confirmed structural causes (exploitable economy, a
test suite that exercises a drifted JS mirror instead of the game, an export that likely
renders no art, UI that cannot fit 1280x800, load-bearing writing that never displays).
The lofty vision is legitimate; the current build is nowhere close, and docs must not
pretend otherwise.

Consequence (decided 2026-07-10): the codex-era Milestone 0.3 batch is burned. The
replacement ladder in `docs/roadmap.md` puts "make what exists real, playable, and
felt" before any new systems.

## Economics

No monthly costs. Free tiers and local compute by default (local Godot, GitHub free CI).
Propose a paid option only when it is architecturally much better, very cheap, and
explicitly justified to Ethan before adoption.

**Art path (decided 2026-07-10):** free/openly-licensed asset packs first, curated hard
for coherence and readability; commissioned or purchased art later (Ethan has friends
who make game art). The current placeholder polygon-and-SVG look is rejected. The art
bible remains the eventual bar, not the current gate.

## How Ethan Works

Ethan vibes this project out between other activities: he gives prompts and
architectural steering; Claude owns execution end to end — including product and design
judgment. His words: this repo is for Claude and only a little bit of him. Two modes,
chosen at will per session:

- **Co-pilot** — Ethan stays in the loop for micro product-design corrections; short
  prompts, fast small ships.
- **Autonomous** — plan together up front, then run the whole batch (including
  overnight) without intervention and report evidence at the end.

Direction he gives should be captured durably here (dated), so he never has to repeat
it. Later, direction gets broken into issue-backed work without re-asking.

## Product Pillars

- **Playable and felt first.** Bold playable drafts over long planning pauses; felt
  experience over systemic completeness. Every milestone leaves the game more playable
  than it found it.
- **Steam Deck first.** 1280x800 readability, controller-first, fast suspend/resume,
  satisfying 10–20 minute sessions. Verified on the actual exported build, not asserted.
- **Market reading is a core pillar.** Demand shifts by season, weather, events, and
  taste; information arrives through the world (customers, gossip, boards, weather
  signs), not a spreadsheet. Paying attention should feel powerful.
- **Writing bar.** Warm, funny when it can be, specific, observant, hopeful without
  lying. No generic cozy wholesomeness. Writing must actually surface in play — an
  unplugged sample pack does not count.
- **Restrained magic.** Magical realism that reveals relationships and care; magic grows
  beside ordinary herbs and stays local, not a power system.
- **Regional specificity.** Plants, customers, customs, and market taste teach the
  player where they are. Multi-region remains the long-term shape, but no new region
  before one region feels alive.
- **Learnable code.** Keep code readable enough that Ethan can learn game programming
  from it.
- **Replayability is deprioritized (decided 2026-07-10).** It was a codex-era criterion;
  fun-on-the-first-run outranks it and it should not drive scope.

## Open Questions (to resolve in future vision sessions)

- Writing production: the working assumption is Claude writes to the pillars and Ethan
  edits for taste — confirm once real dialogue volume starts landing.
- When free-asset art proves the layouts, what triggers the move to commissions — a
  milestone, a feel, or a budget conversation?
