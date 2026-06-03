# Garden Nursery Roadmap

This is the project memory rail for agentic work. Update it when a meaningful system is added or redirected.

## Current Prototype

- Static browser game in `index.html`, `styles.css`, and `game.js`.
- Core loop: inspect market trend, sell plants, restock likely winners, advance week.
- Discovery loop: hybridize two parent plants to create a new stock item.
- Harness: `npm test` runs dependency-light checks through `scripts/agent-check.mjs`.
- Engine direction: research currently recommends migrating the real game to Godot 4.x with GDScript. See `docs/engine-stack-research.md`.

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
- Route ordinary agent work through branches and pull requests instead of direct pushes to `main`.
- Use GitHub Actions sanity checks to verify PR branches remotely.
- Prefer issue-backed work using GitHub issue numbers as the stable work id.
- Add browser smoke tests once the project adopts a dev server or test browser dependency.
- Prefer tests for simulation rules as soon as game logic is split out of DOM rendering.
