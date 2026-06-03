# Garden Nursery

A Steam Deck-first Godot cozy systems narrative game about starting a small nursery, learning local plants and markets, and becoming part of a place through patience, care, and attention.

## Current Direction

Garden Nursery is being developed as a single-player 2D/2.5D cozy nursery sim in Godot 4.x.

The current target is **Godot Vertical Slice 0.1**:

- One starter region.
- A small roadside nursery stand.
- Steam Deck-friendly UI.
- Plant inventory and local market signals.
- Customers with specific needs.
- A week loop with outcomes.
- Writing that is warm, specific, hopeful, and not generic cozy filler.

The old browser prototype in `index.html`, `styles.css`, and `game.js` is only a disposable design sketch until the Godot slice replaces it.

## Key Docs

- `AGENTS.md` - agent workflow and repo rules.
- `docs/session-handoff.md` - shortest handoff for future Codex sessions.
- `docs/creative-direction.md` - game identity, writing pillars, regions, magic, Steam Deck constraints.
- `docs/vertical-slice-0.1.md` - first playable Godot target.
- `docs/starter-region-brief.md` - Hush Arbor starter region brief for the vertical slice.
- `docs/steam-deck-ux-baseline.md` - 1280x800 and controller-first UX baseline.
- `docs/godot-project-structure.md` - planned Godot folder conventions.
- `docs/issue-backlog.md` - current issue queue.
- `docs/agent-pr-workflow.md` - PR-first development process.
- `docs/chatgpt-project-setup.md` - ChatGPT Project setup notes.

## Working Locally

The local development repo lives at:

```sh
/Users/ethanadams/dev/garden-nursery
```

Godot baseline:

```sh
godot --version
```

Expected current version:

```text
4.5.1.stable.official
```

Run the current repo sanity check:

```sh
npm test
```

## Codex Workflow

Start Codex CLI from the repo:

```sh
cd /Users/ethanadams/dev/garden-nursery
cdsp
```

Then ask Codex to work a GitHub issue:

```text
Work issue #5. Follow AGENTS.md.
```

Normal workflow:

1. Inspect the issue and repo docs.
2. Create a task branch.
3. Implement the smallest complete slice.
4. Run `npm test`.
5. Commit cleanly.
6. Open a PR.
7. Wait for GitHub Actions.
8. Squash-merge when passing.

## Next Issue

Start with:

```text
#5 Set up Godot project
```

Recommended issue order is listed in `docs/session-handoff.md`.
