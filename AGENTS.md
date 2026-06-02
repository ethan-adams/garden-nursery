# Garden Nursery Game Agent Notes

## Working Style

This project is intended to be AI slop-first: make bold playable drafts, keep the loop moving, and prefer working prototypes over long planning pauses.

The user wants Codex to make most implementation decisions independently. Ask only when a decision would meaningfully change the identity of the game, require private credentials, spend money, publish something publicly, or destroy existing work.

## Agentic Harness

When given a task, the agent should own the whole loop:

1. Restate the task as a concrete implementation target.
2. Inspect the current code and docs before editing.
3. Break the work into small steps when the task is more than a tiny change.
4. Implement without waiting for approval unless the task crosses a boundary listed in Working Style.
5. Run `npm test` before committing.
6. Commit with a clear message when the work is complete and tests pass.
7. Push to `origin/main` when the user has asked for autonomous repo work or the change is clearly part of the ongoing game build.

If tests fail, fix the failure and rerun them. Do not commit known failing checks unless the user explicitly asks to capture a broken state.

If a task creates a new system, add or update a note in `docs/roadmap.md` so future agents can continue from the current design intent.

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
- Prefer `npm test` as the single pre-commit check entrypoint.
- Keep `scripts/agent-check.mjs` dependency-light unless the game gains a build system.
- Mention any skipped browser/manual verification in the final note.
