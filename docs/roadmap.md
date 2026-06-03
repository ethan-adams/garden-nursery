# Garden Nursery Roadmap

This is the project memory rail for agentic work. Update it when a meaningful system is added or redirected.

## Current Prototype

- Static browser game in `index.html`, `styles.css`, and `game.js`.
- Core loop: inspect market trend, sell plants, restock likely winners, advance week.
- Discovery loop: hybridize two parent plants to create a new stock item.
- Godot project shell under `godot/` with a minimal 1280x800 main scene for the vertical slice.
- First Godot roadside nursery stand scene under `godot/scenes/nursery/nursery_stand.tscn`, driven by JSON catalogs and playable as a market-reading/recommendation loop.
- Core content data format chosen: JSON catalogs for starter plants, Hush Arbor customer archetypes, region market signals/outcomes, and dialogue samples.
- Hush Arbor market-reading prototype: players cycle imperfect signal sources, recommend a plant, and see cash/reputation/week outcome text respond to trait matches and risks.
- Writing sample pack added in `docs/writing-sample-pack.md` and `godot/data/dialogue/writing_sample_pack.json` with recurring characters, barks, reflections, and a seed-swap event.
- Steam Deck UX baseline documented in `docs/steam-deck-ux-baseline.md`: 1280x800 target, readable text, controller-first focus navigation, semantic UI input action names, and current automatic/manual check boundaries.
- Starter region brief documented in `docs/starter-region-brief.md`: Hush Arbor, a forgiving temperate valley with porch gardens, orchard culture, mild magical realism, and gentle market-reading signals.
- Harness: `npm test` runs dependency-light checks through `scripts/agent-check.mjs`.
- CI: GitHub Actions runs `npm test` plus a cached official Godot 4.5.1 Linux headless import check for the `godot/` project.
- Engine direction: the real game is migrating to Godot 4.5.x with GDScript. See `docs/engine-stack-research.md`.

## North Star

Make a cozy, systemic nursery game where the player learns to read plants, customers, seasons, and regional taste. It should feel like spending a Saturday at a good nursery: tactile, alive, observant, and full of small discoveries.

See `docs/creative-direction.md` for the current creative direction, including the fictional-country region plan, writing pillars, magical realism rules, Steam Deck constraints, and market-reading pillar.

## Next Systems To Consider

- Godot migration spike with one playable nursery loop.
- Propagation bench with time, failure chance, and plant-specific methods.
- Customer archetypes with garden constraints, budgets, and taste memory.
- Regional climate model: heat, frost dates, water restrictions, soil, and native ranges.
- Plant genetics model for hybrid traits, rarity, stability, and naming.
- Nursery layout where bench placement affects browsing, care, and sales.
- Journal that records discovered varieties, customer notes, and market reads.

## Harness Goals

- Keep `npm test` fast enough to run before every commit.
- Verify the Godot project file, main scene, and local placeholder assets before PRs.
- Route ordinary agent work through branches and pull requests instead of direct pushes to `main`.
- Use GitHub Actions sanity checks to verify PR branches remotely.
- Prefer issue-backed work using GitHub issue numbers as the stable work id.
- Add browser smoke tests once the project adopts a dev server or test browser dependency.
- Prefer tests for simulation rules as soon as game logic is split out of DOM rendering.
