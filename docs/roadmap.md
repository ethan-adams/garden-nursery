# Garden Nursery Roadmap

This is the project memory rail for agentic work. Update it when a meaningful system is added or redirected.

## Current Prototype

- Static browser game in `index.html`, `styles.css`, and `game.js`.
- Core loop: inspect market trend, sell plants, restock likely winners, advance week.
- Discovery loop: hybridize two parent plants to create a new stock item.
- Godot project shell under `godot/` with a minimal 1280x800 main scene for the vertical slice.
- Walkable 2.5D nursery yard foundation under `godot/scenes/nursery/nursery_yard.tscn`, with player movement, camera, Hush Arbor yard blockout, and station placeholders.
- First Hush Arbor yard art/UX pass uses editable SVG source art and PNG runtime assets for a warmer roadside nursery first screen instead of crude scene-tree blockout shapes.
- First Godot roadside nursery stand scene under `godot/scenes/nursery/nursery_stand.tscn`, driven by JSON catalogs and playable as a market-reading/recommendation loop.
- Core content data format chosen: JSON catalogs for starter plants, Hush Arbor customer archetypes, region market signals/outcomes, and dialogue samples.
- Hush Arbor market-reading prototype: players cycle imperfect signal sources, recommend a plant, and see cash/reputation/week outcome text respond to trait matches and risks.
- Propagation bench prototype: players can start one active plant tray with plant-specific method, cost, time, yield, and success chance; completed trays feed back into inventory on week advance.
- Writing sample pack added in `docs/writing-sample-pack.md` and `godot/data/dialogue/writing_sample_pack.json` with recurring characters, barks, reflections, and a seed-swap event.
- Steam Deck UX baseline documented in `docs/steam-deck-ux-baseline.md`: 1280x800 target, readable text, controller-first focus navigation, semantic UI input action names, and current automatic/manual check boundaries.
- Starter region brief documented in `docs/starter-region-brief.md`: Hush Arbor, a forgiving temperate valley with porch gardens, orchard culture, mild magical realism, and gentle market-reading signals.
- Harness: `npm test` runs dependency-light checks through `scripts/agent-check.mjs`.
- Product testing: `npm test` validates repo/data/scene shape, while `npm run test:product` adds a Godot headless smoke test for scene/script/resource failures.
- CI: GitHub Actions runs `npm test`, a cached official Godot 4.5.1 Linux headless import check, and a Steam Deck/Linux debug export artifact build.
- Steam Deck playtest path documented in `docs/testing-and-builds.md`; debug exports are produced into `dist/steamdeck/` locally or as GitHub Actions artifacts.
- Engine direction: the real game is migrating to Godot 4.5.x with GDScript. See `docs/engine-stack-research.md`.

## North Star

Make a cozy, systemic nursery game where the player learns to read plants, customers, seasons, and regional taste. It should feel like spending a Saturday at a good nursery: tactile, alive, observant, and full of small discoveries.

See `docs/creative-direction.md` for the current creative direction, including the fictional-country region plan, writing pillars, magical realism rules, Steam Deck constraints, and market-reading pillar.

## Next Systems To Consider

- Continue raising the walkable yard quality bar: composition, station readability, interaction prompts, movement feel, and Steam Deck first-screen readability.
- In-world interaction framework that opens market, plant stand, propagation, and ledger surfaces from yard objects.
- Customer archetypes with garden constraints, budgets, and taste memory.
- Regional climate model: heat, frost dates, water restrictions, soil, and native ranges.
- Plant genetics model for hybrid traits, rarity, stability, and naming.
- Nursery layout where bench placement affects browsing, care, and sales.
- Journal that records discovered varieties, customer notes, and market reads.

## Harness Goals

- Keep `npm test` fast enough to run before every commit.
- Use `npm run test:product` before pushing Godot scene/script/resource changes.
- Keep Steam Deck debug exports building in CI so playtest artifacts are routine.
- Verify the Godot project file, main scene, and local placeholder assets before PRs.
- Route ordinary agent work through branches and pull requests instead of direct pushes to `main`.
- Use GitHub Actions sanity checks to verify PR branches remotely.
- Prefer issue-backed work using GitHub issue numbers as the stable work id.
- Add browser smoke tests once the project adopts a dev server or test browser dependency.
- Prefer tests for simulation rules as soon as game logic is split out of DOM rendering.
