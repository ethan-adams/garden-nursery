# Garden Nursery Roadmap

This is the project memory rail for agentic work. Update it when a meaningful system is added, redirected, or cut.

GitHub issues are the source of truth for executable tasks. This document explains the end-to-end product path and why the issue batches exist.

## Current Prototype

- Product path: Godot 4.5.x under `godot/`.
- Browser prototype: archived under `browser-prototype/` as a disposable design sketch.
- Main scene: `godot/scenes/main/main.tscn` loads `godot/scenes/nursery/nursery_yard.tscn`.
- Yard: walkable 2.5D Hush Arbor nursery first screen with player movement, camera, local yard art, and interactive stations for signal board, plant stand, propagation bench, and ledger.
- Existing playable loop: `godot/scenes/nursery/nursery_stand.tscn` holds the market-reading, customer-specific recommendation, propagation, and ledger week-advance prototype as station-focused overlays launched from the yard.
- Data: JSON catalogs for starter plants, Hush Arbor customers, region signals/outcomes, and dialogue samples.
- Content size: 16 starter plants, 3 recurring customers, 4 market signals, and 3 week outcomes.
- Recommendations: plants score against each recurring customer's budget, site constraints, taste, and current market signal; outcomes can differ by customer and create relationship notes for the current run.
- Ledger: week close summarizes cash, reputation, inventory, propagation progress, market learning, Hush Arbor consequences, and recent customer notes.
- Propagation: three active bench tray slots with plant-specific method, cost, time, yield, success chance, and gentle partial-success/failure outcomes.
- Care/climate fit: Hush Arbor has a readable climate profile for water, light, soil, frost, and heat. Plant care now affects recommendation quality, propagation odds, plant cards, and journal notes without making the starter region punitive.
- Season/weather calendar: Hush Arbor has weekly beats from early spring frost through damp autumn. Forecasts merge into market signals, affect demand traits, adjust propagation outcomes, and appear in station headers and ledger summaries.
- Customer memory: recurring customers now track visits, satisfaction, prior recommendations, last plants, and unresolved needs. Returning beats show in customer cards, journal notes, and ledger trust summaries.
- Restock economy: the plant stand has a supplier order action for the selected plant, with derived wholesale cost, shelf caps, margin notes, weekly restock spend, and ledger shortage/overstock reads.
- Yard onboarding: the walkable yard now guides new players through signal board, plant stand, propagation bench, ledger, and journal using short contextual station prompts that disappear as stations are visited.
- Seed-swap event: Hush Arbor has a small timed community event with preferred traits, etiquette text, plant contributions from inventory, deadline resolution, rewards, reputation, relationship notes, and ledger/journal consequences.
- Station readability art: the yard has editable local station markers, material-colored plaques, and path-edge accents for the signal board, plant stand, propagation bench, ledger, and journal so the workbench loop reads before prompt text.
- Save/load: the vertical slice auto-loads and auto-saves `user://garden_nursery_vertical_slice_save.json`; the stand header has a reset-run action for testing. Format notes live in `docs/vertical-slice-save-format.md`.
- Discovery journal: a yard journal station renders discovered plant notes, customer memories, market reads, and ledger week reflections while hiding undiscovered information behind uncertainty counts.
- Simulation tests: `npm test` runs dependency-light recommendation scoring rule tests covering trait matches, risk traits, budgets, constraints, and reputation outcomes.
- Playtest build notes: `docs/vertical-slice-0.1-playtest-build.md` points testers to the `garden-nursery-steamdeck-debug` GitHub Actions artifact and names controls, known limits, and feedback prompts.
- Refactor track: Godot recommendation scoring rules live in `godot/scripts/core/nursery_rules.gd`; saveable run state lives in `godot/scripts/core/nursery_run_state.gd`.
- Docs: creative direction, starter region, Steam Deck UX baseline, art bible, visual pipeline, testing/builds, and issue backlog are in `docs/`.
- Harness: `npm test` validates data and dependency-light repo shape; `npm run test:product` adds Godot headless smoke.
- CI: GitHub Actions sanity checks and Steam Deck/Linux debug export artifacts are in place.

## North Star

Make a cozy, systemic nursery game where the player learns to read plants, customers, seasons, and regional taste. It should feel like spending a Saturday at a good nursery: tactile, alive, observant, and full of small discoveries.

The game is not just retail and not "Stardew but plants." The playable fantasy is learning a place through nursery work: propagation, customer care, market reading, seasonal adaptation, plant discovery, and region-specific constraints.

See `docs/creative-direction.md` for the creative authority.

## Roadmap Shape

The roadmap is organized as playable milestones, not departments. Each milestone should leave the game more playable than it found it — and, per the player-zero rule in `docs/VISION.md`, more interesting to Ethan than it found it.

1. Finish the Godot Vertical Slice 0.1. (Done.)
2. Make Hush Arbor a repeatable alpha nursery. (Issues closed; quality bar not met — see the honest status under Milestone 2.)
3. Make what exists real, playable, and felt (`0.3 Make It Real`).
4. Build the minute-to-minute fantasy: a day of care inside a season of plans.
5. Make Hush Arbor emotionally and seasonally alive.
6. Expand regions, then harden for Steam Deck beta.

## Milestone Ladder

Reset 2026-07-10 after the vision Q&A and critical review (see `docs/VISION.md`). The codex-era backlog (#51–#71) is closed as not-planned — its acceptance criteria reduced to green CI, the self-grading pattern the reset retired; new systems wait until the existing game is honest and felt.

- `0.1 Vertical Slice` (done): prove the walkable yard, station overlays, market reading, recommendations, propagation, ledger, save/load, and journal.
- `0.2 Hush Arbor Alpha` (issues closed, bar not met): stateful simulation, propagation capacity, weather, care, memory, economy, onboarding, and seed-swap play exist in code, but the loop is exploitable and the build doesn't feel real.
- `0.3 Make It Real` (current, #91–#101): honest economy, working export art, controller UI that fits 1280x800, writing that surfaces in play, a full-year calendar, coherent free-asset art, and foundations (plant instances, region-clean rules, behavioral tests) that can carry later systems.
- `0.4 A Living Day` (to be scoped after 0.3): the minute-to-minute fantasy from `docs/VISION.md` — a day structure with care tasks, seasonal planning bets, visible plant growth, customers present in the world, and medium/long-term plans the player can see progressing.
- `0.5 Living Hush Arbor` (re-scope of old 0.4, plus the deferred systemic-nursery ideas from #51–#56 that survive contact with 0.4): character arcs, festivals, seasonal presentation, layout/structures, hybridizing.
- Later: multi-region campaign, then production beta. Unchanged in ambition, unscheduled on purpose.

## Milestone 1: Godot Vertical Slice 0.1

Goal: prove the core loop as a Steam Deck-first Godot game: walk around the nursery, read local signals, use in-world stations, prepare stock, serve customers, close the week, and see consequences.

Completed foundation:

- `#5` Set up Godot project.
- `#6` Define starter region brief.
- `#7` Define core data model.
- `#8` Establish Steam Deck UX baseline.
- `#9` Prototype market-reading loop.
- `#10` Build first nursery stand scene.
- `#12` Add Godot CI sanity check.
- `#13` Create writing sample pack.
- `#26` Build walkable 2.5D nursery yard foundation.
- `#27` Add in-world interaction station framework.
- `#28` Move nursery loop into world station overlays.
- `#29` Rework Hush Arbor yard art direction and first-screen UX.
- `#30` Polish walkable yard camera, collision, and controller feel.
- `#31` Add sanity checks for walkable world scene.
- `#35` Expand Hush Arbor starter plant catalog to vertical-slice size.
- `#36` Add customer-specific recommendation outcomes.
- `#37` Add end-of-week ledger with relationship notes.
- `#38` Add save and load for vertical-slice state.
- `#39` Add discovery journal MVP.
- `#40` Add simulation rule tests for market and recommendation scoring.
- `#41` Cut Godot Vertical Slice 0.1 playtest build.

Remaining tasks:

- None. Continue with Milestone 2 once the playtest build PR is merged and checked.

Exit criteria:

- The first screen is the walkable nursery yard.
- The original loop is playable through in-world stations.
- The player can complete at least one readable week with market clues, customer recommendations, propagation, ledger outcome, save/load, and journal notes.
- The slice has 12-20 Hush Arbor plants and at least three recurring customers with distinct needs.
- `npm test`, `npm run test:product`, and GitHub Actions pass.
- A Steam Deck/Linux debug build is available for playtesting.

## Milestone 2: Playable Hush Arbor Alpha 0.2

Goal: make Hush Arbor feel like a small repeatable nursery game rather than a one-week proof.

Tasks:

- `#42` Extract nursery simulation state from UI scenes. Complete.
- `#43` Build multi-tray propagation queue. Complete.
- `#44` Add plant care needs and climate-fit consequences. Complete.
- `#45` Add season and weather calendar for Hush Arbor. Complete.
- `#46` Add customer memory and returning relationship beats. Complete.
- `#47` Add inventory pricing and restock economy. Complete.
- `#48` Add yard onboarding flow. Complete.
- `#49` Add Hush Arbor seed-swap event loop. Complete.
- `#50` Replace placeholder station art with production-readable Hush Arbor assets. Complete.

Exit criteria (honest status, 2026-07-10): the issue batch is closed but the criteria were never actually evaluated, and the 2026-07-10 critical review plus Ethan's own playtest falsify them — the loop is exploitable (free week outcomes, unlimited actions), the calendar freezes after week 5, the stand overlay cannot fit 1280x800 with controller focus, and the build does not feel real. Milestone 0.3 exists to make these criteria true before anything new is built.

## Milestone 3: Make It Real 0.3

Goal: make what exists real, playable, and felt. No new systems until the current game is honest — economy with constraints, art that renders, UI that fits the Deck, writing that surfaces, and foundations that can carry future systems.

Tasks (GitHub milestone `0.3 Make It Real`):

- `#91` Fix the always-paying week outcome (free money bug).
- `#92` Fix exported-build art rendering (import pipeline).
- `#93` Give the week a real action economy.
- `#94` Plant stand UI fits 1280x800 with working controller focus.
- `#95` Surface the writing pack in play.
- `#96` Select a plant without selling it.
- `#97` Refactor: plant instances, region-clean rules, state/presentation split.
- `#98` Behavioral tests that exercise the actual game.
- `#99` Season calendar runs a full year.
- `#100` Replace placeholder art with a coherent free asset pass.
- `#101` Seed and persist week-close RNG.

Exit criteria:

- Ethan plays the exported Steam Deck build and reports it feels like a game, not a set of forms. This is the gate that matters.
- No known way to earn cash or reputation without meaningful play.
- Every station overlay is controller-navigable and readable at 1280x800 on the actual exported build.
- The player reads writing-pack-quality prose during ordinary play.
- CI exercises real GDScript simulation behavior.

The codex-era batch (`#51`–`#56`: layout, structures, hybridizing, cultivars, suppliers/competitors, water/soil/regulation) is closed as not-planned; whatever survives contact with `docs/VISION.md` after this milestone gets re-created with felt acceptance criteria.

## Later Milestones (pending re-scope after 0.3)

The sections below predate the 2026-07-10 reset. Their ambitions stand, but their task batches and ordering will be re-scoped against `docs/VISION.md` once `0.3 Make It Real` completes — with a new `0.4 A Living Day` milestone (day structure, care tasks, seasonal bets, customers in the world) scoped first.

## Milestone 4: Living Hush Arbor Alpha 0.4

Goal: make the starter region emotionally and seasonally alive.

Tasks:

- `#57` Add Hush Arbor character arcs for regular customers.
- `#58` Add festivals and community board requests.
- `#59` Add seasonal visual and audio state changes.
- `#60` Add late-season evaluation and Hush Arbor mastery loop.
- `#61` Add accessibility and settings pass.

Exit criteria:

- At least three regulars have visible seasonal arcs.
- Community requests and festivals create timed local demand.
- The yard changes across season/weather states.
- A Hush Arbor season has a satisfying evaluation and region-mastery loop.
- Accessibility and settings are solid enough to carry forward before content multiplies.

## Milestone 5: Multi-Region Campaign Alpha 0.5

Goal: expand beyond one region while preserving regional specificity.

Tasks:

- `#62` Define country map and reusable region content template.
- `#63` Add hot dry region prototype.
- `#64` Add cold hard-mode region prototype.
- `#65` Add region travel and specialty unlocks.
- `#66` Add cross-region plant adaptation rules.

Exit criteria:

- The country has a clear 5-6 region shape.
- Region data has a reusable template for climate, customs, market pressure, customers, plant specialties, events, and magic rules.
- At least two non-Hush Arbor regions prove that strategies do not transfer cleanly everywhere.
- Travel, unlocks, and cross-region adaptation rules are playable and saved.

## Milestone 6: Production Beta 0.8

Goal: turn the alpha into a shippable Steam Deck-first game.

Tasks:

- `#67` Add Steam Deck performance budget and profiling gate.
- `#68` Add full controller remapping and input prompt polish.
- `#69` Add save migration and compatibility checks.
- `#70` Run full economy, content, and pacing balance pass.
- `#71` Prepare release candidate checklist.

Exit criteria:

- Steam Deck performance, input, save compatibility, accessibility, and export flow are repeatable.
- Balance has been reviewed across the full available campaign.
- A release candidate can be evaluated from documented checklists instead of memory.

## Persistent Product Pillars

Every milestone should protect these:

- Browser-playable is no longer the product target; Godot is.
- Steam Deck-first means controller navigation, 1280x800 readability, legible prompts, and no pointer-only core actions.
- Systems should be visible and testable before they become deep.
- Writing must be warm, specific, and observant, not generic cozy filler.
- Regional specificity matters: plants, customers, weather, customs, and market taste should teach the player where they are.
- Magic should be local, restrained, and relational rather than a generic power system.
- Keep the first screen alive and plant-forward. Do not regress into dashboard-first development.

## Harness Goals

- Keep `npm test` fast enough to run before every commit.
- Use `npm run test:product` before pushing Godot scene/script/resource changes.
- Keep Steam Deck debug exports building in CI so playtest artifacts are routine.
- Deliver ordinary work through the `/ship` pipeline: one coherent `Harness-Managed: true`
  commit pushed to `main`, with CI auto-reverting a failing harness-managed head.
- Prefer issue-backed work using GitHub issue numbers as stable work ids.
- Add tests for simulation rules as game logic moves out of UI scene scripts.
- See the root `CLAUDE.md` for the full workflow contract.
