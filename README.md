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

The old browser prototype in `browser-prototype/` is only a disposable design sketch. The product path is the Godot project under `godot/`.

## Key Docs

- `AGENTS.md` - agent workflow and repo rules.
- `docs/session-handoff.md` - shortest handoff for future Codex sessions.
- `docs/creative-direction.md` - game identity, writing pillars, regions, magic, Steam Deck constraints.
- `docs/art-bible.md` - production visual target, palette, UI, composition, and asset acceptance bar.
- `docs/visual-development-pipeline.md` - repeatable visual research, asset brief, production, integration, and review workflow.
- `docs/vertical-slice-0.1.md` - first playable Godot target.
- `docs/starter-region-brief.md` - Hush Arbor starter region brief for the vertical slice.
- `docs/steam-deck-ux-baseline.md` - 1280x800 and controller-first UX baseline.
- `docs/godot-project-structure.md` - planned Godot folder conventions.
- `docs/testing-and-builds.md` - local, CI, Mac, and Steam Deck testing process.
- `docs/decisions.md` - lightweight project decision log.
- `docs/claude-brief-review.md` - critical review of the Claude-generated planning brief.
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

Run the stronger Godot product check before pushing scene or script changes:

```sh
npm run test:product
```

Run the Godot prototype locally:

```sh
npm run godot:run
```

Export a Steam Deck/Linux debug build:

```sh
npm run export:steamdeck
```

See `docs/testing-and-builds.md` for the standard Mac and Steam Deck playtest flow.

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

## Current Next Work

The first issue queue is complete. The next useful tickets should harden the playable loop: propagation queue, customer-specific recommendation outcomes, expanded Hush Arbor plant catalog, and controller/layout playtest checks.
