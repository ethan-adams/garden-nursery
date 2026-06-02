# Agent PR Workflow

Use this workflow for normal autonomous changes.

## Loop

1. Start from an up-to-date `main`.
2. Create a task branch with a descriptive prefix:
   - `feature/` for player-facing systems.
   - `fix/` for bugs and regressions.
   - `chore/` for harness, repo, or maintenance work.
   - `docs/` for documentation-only changes.
3. Inspect the relevant code and docs.
4. Implement the smallest complete playable slice.
5. Run `npm test`.
6. Commit a clean, coherent change.
7. Push the branch.
8. Open a PR to `main` with `gh pr create --fill` or an explicit title/body.
9. Check PR status with `gh pr checks`.

## Clean History Rules

- One focused task should usually become one commit.
- Keep commits readable with conventional prefixes like `feat:`, `fix:`, `chore:`, `docs:`, and `test:`.
- Avoid checkpoint commits in published PRs.
- If a branch gets messy before it is pushed, clean it locally before opening the PR.

## Required Sanity Check

`npm test` is the local and CI entrypoint. It currently verifies:

- `game.js` parses.
- `index.html` loads the expected CSS and JS.
- Referenced visual assets are local and present.
- The prototype still exposes the core game-loop functions.

Add checks to `scripts/agent-check.mjs` when a new system becomes important enough that future agents should not casually break it.
