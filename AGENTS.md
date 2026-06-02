# Garden Nursery Game Agent Notes

## Working Style

This project is intended to be AI slop-first: make bold playable drafts, keep the loop moving, and prefer working prototypes over long planning pauses.

The user wants Codex to make most implementation decisions independently. Ask only when a decision would meaningfully change the identity of the game, require private credentials, spend money, publish something publicly, or destroy existing work.

## Game Direction

- Cozy but systemic nursery game about gardening, regional plant markets, and plant discovery.
- The fantasy is not just retail. It should capture the feeling of browsing a nursery, learning plants, noticing seasons, and finding joy in living things.
- Core systems should eventually include:
  - Regional market demand.
  - Plant traits and local climate fit.
  - Propagation and greenhouse/nursery layout.
  - Hybridizing, heirlooms, and variety discovery.
  - Customer archetypes with taste, budget, and garden constraints.

## Prototype Bias

- Always keep the game playable in a browser.
- Add visible, testable systems before deep architecture.
- Prefer small simulations with expressive text over empty UI scaffolding.
- Keep code readable enough that the user can learn game coding from it.
- Use local assets when practical so the prototype is easy to run offline.

## Visual Taste

- Warm, tactile, plant-forward, and region-aware.
- Avoid generic fantasy farming vibes unless a feature specifically calls for them.
- UI should feel like a useful nursery workbench: organized, alive, and gently charming.

## Repo Hygiene

- Keep changes scoped and commit-friendly.
- Do not overwrite user work.
- Before pushing, verify the configured remote and branch.
