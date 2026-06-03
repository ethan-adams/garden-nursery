# Garden Nursery Game Agent Notes

## Working Style

This project is intended to be AI slop-first: make bold playable drafts, keep the loop moving, and prefer working prototypes over long planning pauses.

The user wants Codex to make most implementation decisions independently. Ask only when a decision would meaningfully change the identity of the game, require private credentials, spend money, publish something publicly, or destroy existing work.

## Agentic Harness

When given a task, the agent should own the whole loop:

1. Restate the task as a concrete implementation target.
2. If an issue number is provided, inspect it with `gh issue view <number>`, for example `gh issue view 5`.
3. Inspect the current code and docs before editing.
4. Break the work into small steps when the task is more than a tiny change.
5. Create or switch to a task branch before editing. Use branch names based on the GitHub issue number when possible, such as `feature/5-godot-project`, `docs/6-starter-region`, or `chore/12-godot-ci`.
6. Implement without waiting for approval unless the task crosses a boundary listed in Working Style.
7. Run `npm test` before committing.
8. Commit with a clear message when the work is complete and tests pass.
9. Push the task branch and open a pull request against `main`.
10. Confirm GitHub sanity checks are passing or report exactly what failed.
11. Squash-merge the PR when checks pass, unless the user explicitly asks to review first.

If tests fail, fix the failure and rerun them. Do not commit known failing checks unless the user explicitly asks to capture a broken state.

If a task creates a new system, add or update a note in `docs/roadmap.md` so future agents can continue from the current design intent.

Do not push directly to `origin/main` for ordinary work. `main` should move through pull requests so the history stays reviewable and CI has a chance to catch mistakes.

Before opening a PR, keep the branch history clean:

- Prefer one coherent commit for a focused task.
- Use two or more commits only when they tell a useful story, such as `Add propagation model` followed by `Render propagation bench`.
- If the branch has noisy checkpoint commits, squash or reset them before publishing the PR.
- Do not rewrite shared branches after a PR is open unless the user asks or the cleanup is clearly harmless.

PR titles should start with one of:

- `feat:`
- `fix:`
- `chore:`
- `docs:`
- `test:`

Issue-backed work should use GitHub issue numbers as the stable work id. PR bodies should link the issue with `Closes #N` when the PR completes it.

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
- Use the PR template in `.github/PULL_REQUEST_TEMPLATE.md`.
- Use GitHub Actions sanity checks as the remote source of truth after pushing a PR branch.
- Mention any skipped browser/manual verification in the final note.

## Tooling Baseline

- Local repo path: `/Users/ethanadams/dev/garden-nursery`.
- GitHub repo: `ethan-adams/garden-nursery`.
- Current Godot baseline: `4.5.1.stable`.
- Use `godot --version` to verify the local engine.
- Prefer plain Codex CLI prompts from the repo root, such as `Work issue #5. Follow AGENTS.md.`
