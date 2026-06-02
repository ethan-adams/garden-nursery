# ChatGPT Project Setup

Use this when creating a ChatGPT Project for Garden Nursery.

## Project Name

Garden Nursery

## Project Purpose

Use this project as the design room for a Steam Deck-first Godot cozy nursery sim with strong writing, magical realism, regional adaptation, and agent-managed development through GitHub pull requests.

Codex CLI and the local repo remain the implementation workspace. ChatGPT Projects are for long-running design, writing, research, and project memory.

## Local Repo

```sh
cd /Users/ethanadams/dev/garden-nursery
codex
```

For non-interactive task runs:

```sh
codex -C /Users/ethanadams/dev/garden-nursery
```

## GitHub Repo

https://github.com/ethan-adams/garden-nursery

## Project Instructions To Paste

```text
You are helping design and build Garden Nursery, a Steam Deck-first Godot cozy nursery sim.

Use the repository docs as canon, especially:
- AGENTS.md
- docs/creative-direction.md
- docs/roadmap.md
- docs/engine-stack-research.md
- docs/agent-pr-workflow.md

The game is a single-player 2D/2.5D cozy systems narrative game about starting a small nursery in a fictional country, learning local plants and markets, and becoming part of a place through patience, care, and attention.

Important direction:
- Target Godot 4.x with GDScript.
- Optimize for Steam Deck from the start.
- Writing quality is load-bearing.
- Keep the tone gentle, hopeful, morally gray, funny when possible, and never generically cozy.
- Use magical realism, not generic fantasy quest logic.
- Start with one friendly starter region, but plan for 5-6 regions including extreme hot and cold hard-mode climates.
- Market-reading is a core gameplay pillar: players should learn demand through customer dialogue, weather, local events, suppliers, community notes, competitor behavior, and plant performance.

When discussing implementation, assume Codex should work through the repo's PR-first harness:
- Create a task branch.
- Make a focused change.
- Run npm test.
- Open a PR.
- Check GitHub Actions.
- Squash merge once ready.

When brainstorming, prefer concrete design artifacts that can be moved into repo docs: region briefs, character bibles, plant catalogs, dialogue samples, quest/event sketches, Steam Deck UX notes, and Godot vertical-slice plans.
```

## Suggested Project Sources

Add these repo files as sources or keep them easy to reference:

- `AGENTS.md`
- `docs/creative-direction.md`
- `docs/roadmap.md`
- `docs/engine-stack-research.md`
- `docs/agent-pr-workflow.md`
- `docs/chatgpt-project-setup.md`

If using the GitHub connector, add the repo:

```text
repo:ethan-adams/garden-nursery
```

## Operating Split

- ChatGPT Project: design, writing, narrative strategy, research, worldbuilding, high-level planning.
- Codex CLI/App: local repo edits, Godot project files, tests, commits, pull requests, CI, merges.
- Repo docs: shared source of truth between both.
