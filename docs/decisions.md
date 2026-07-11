# Decisions

Agents append to this file when a decision changes how the project is built, tested, structured, or designed. Do not rewrite old entries except to fix clear factual errors.

## 2026-06-03 - Product checks protect Godot first

**Decision:** The standard change gate is `npm test`, with `npm run test:product` required for Godot scene or script changes.

**Reason:** The browser prototype is disposable. The product is the Godot vertical slice, and GDScript/resource errors need to fail before PR review.

**Consequence:** Local checks stay fast, while product-impacting changes have a stronger opt-in check that requires Godot on `PATH`.

## 2026-06-03 - Steam Deck builds are Linux debug exports

**Decision:** Steam Deck playtest builds use the committed `Steam Deck` Godot export preset and `npm run export:steamdeck`.

**Reason:** Steam Deck runs Linux well, and a standard export artifact is easier to test repeatedly than asking each tester to run the Godot editor.

**Consequence:** Export templates are now part of the build process. CI installs them, and local machines need them installed for local exports.

## 2026-07-10 - Codex harness replaced with Claude harness

**Decision:** The codex-era agent harness (`AGENTS.md`, PR-first workflow, ChatGPT design-room split) is replaced by a Claude harness: root `CLAUDE.md` contract, `docs/VISION.md` steering doc, a `/ship` skill with a multi-agent adversarial review gate (`.claude/`), and optimistic trunk delivery — verified `Harness-Managed: true` commits push directly to `main`, and the Sanity workflow auto-reverts a failing harness-managed head.

**Reason:** Claude Code owns orchestration natively (skills, subagents, workflows), so the PR ceremony existed only to gate CI, and the process docs were codex-specific. The model mirrors the ethanadams.dev harness contract.

**Consequence:** `AGENTS.md`, `docs/agent-pr-workflow.md`, `docs/chatgpt-project-setup.md`, and `docs/claude-brief-review.md` are deleted. Game direction from `AGENTS.md` moved to `docs/VISION.md`. PRs remain available for work Ethan wants to review first.

## 2026-07-10 - Decisions preserved from the deleted Claude brief review

**Decision:** Recording the still-relevant rejected paths from `docs/claude-brief-review.md` before its deletion: plant catalogs live under `godot/data/`, not a root `data/` directory; Hush Arbor is a fictional region — real-world Northeast plant facts are inspiration, never canonical content.

**Reason:** The rest of that review was stale meta-commentary on an old planning brief, but these two choices still bind content work.

**Consequence:** Content and data changes keep following the `godot/data/` catalog structure and fictional-region rule without needing the deleted doc.
