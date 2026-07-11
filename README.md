# Garden Nursery

A Steam Deck-first Godot cozy systems narrative game about starting a small nursery, learning local plants and markets, and becoming part of a place through patience, care, and attention.

## Current Direction

Garden Nursery is being developed as a single-player 2D/2.5D cozy nursery sim in Godot 4.x.

The vertical slice (0.1) and the Hush Arbor alpha issue batch (0.2) are complete; current work is **Nursery Systems Alpha 0.3**, starting at issue `#51`.

The old browser prototype in `browser-prototype/` is only a disposable design sketch. The product path is the Godot project under `godot/`.

## Key Docs

- `CLAUDE.md` - the Claude harness contract: workflow, delivery, and verification rules.
- `docs/VISION.md` - durable product direction and how Ethan works with the harness.
- `docs/session-handoff.md` - shortest handoff for future sessions.
- `docs/creative-direction.md` - game identity, writing pillars, regions, magic, Steam Deck constraints.
- `docs/art-bible.md` - production visual target, palette, UI, composition, and asset acceptance bar.
- `docs/visual-development-pipeline.md` - repeatable visual research, asset brief, production, integration, and review workflow.
- `docs/vertical-slice-0.1.md` - first playable Godot target.
- `docs/starter-region-brief.md` - Hush Arbor starter region brief for the vertical slice.
- `docs/steam-deck-ux-baseline.md` - 1280x800 and controller-first UX baseline.
- `docs/godot-project-structure.md` - planned Godot folder conventions.
- `docs/testing-and-builds.md` - local, CI, Mac, and Steam Deck testing process.
- `docs/vertical-slice-0.1-playtest-build.md` - current playtest artifact, controls, known issues, and feedback prompts.
- `docs/decisions.md` - lightweight project decision log.
- `docs/issue-backlog.md` - current issue queue.
- `docs/roadmap.md` - end-to-end product roadmap and milestone ladder.

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

## Claude Workflow

Start Claude Code from the repo:

```sh
cd /Users/ethanadams/dev/garden-nursery
claude
```

Then ship the next queued GitHub issue:

```text
/ship next
```

Or a specific issue or task:

```text
/ship 51
```

The `/ship` pipeline scopes the task, implements it, runs a multi-agent adversarial
review gate, verifies with `npm test` / `npm run test:product`, pushes a
`Harness-Managed: true` commit to `main`, and monitors CI, which auto-reverts a failing
harness-managed head. See `CLAUDE.md` for the full contract.

## Current Next Work

The roadmap is issue-backed end to end. Continue with the Nursery Systems Alpha 0.3 batch starting at `#51`.
