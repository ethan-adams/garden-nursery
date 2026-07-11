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

## 2026-07-10 - Vision reset: player-zero rule and Make It Real 0.3

**Decision:** After the vision Q&A with Ethan, `docs/VISION.md` is the reset steering doc: the project exists for Ethan learning game dev and building a world that feels alive (Steam someday, revenue never); whatever keeps the game interesting to Ethan ships first; replayability is deprioritized. The codex-era `Nursery Systems Alpha 0.3` batch (`#51`–`#56`) is deferred/blocked and replaced by `Make It Real 0.3` (`#91`–`#101`), driven by the 2026-07-10 critical review (exploitable economy, broken export art, UI overflow at 1280x800, unplugged writing, drifted JS test mirror, frozen calendar).

**Reason:** Ethan played the build and judged it dead-feeling; the review found the milestone-2 exit criteria were never actually evaluated. New systems on top of a false foundation would compound the drift.

**Consequence:** No new simulation systems until 0.3's exit gate passes — Ethan plays the exported Steam Deck build and reports it feels like a game. Art path is free/openly-licensed packs first, commissions later.

## 2026-07-10 - Codex-era backlog closed as not-planned

**Decision:** Open issues `#51`–`#71` (the codex-authored 0.3–0.8 batches) are closed as not-planned, superseding the earlier same-day choice to merely block `#51`–`#56`. The open queue now contains only the evidence-backed `Make It Real 0.3` issues (`#91`–`#101`).

**Reason:** Ethan flagged that codex-created issues may be wrong or the wrong thing to solve. Audit confirmed the pattern: thin bodies whose acceptance criteria reduce to "npm test passes" — the self-grading loop that produced a dead-feeling game. Several also contradicted the reset vision (new regions before one region feels alive, balance passes over content that does not exist). They were also still `agent-ready`, so `/ship next` could have claimed them ahead of the new batch.

**Consequence:** The ambitions live on in `docs/roadmap.md`'s Later Milestones section only. Future issues get re-created from `docs/VISION.md` with observable, felt acceptance criteria; green CI alone is never a "done" condition again.

## 2026-07-10 - Weekly action economy: visits scale with reputation

**Decision:** The week is bounded by a small pool of "visits" (issue #93). Recommending, restocking, and starting a propagation tray each spend one visit; when they run out the stand closes until the week is closed. The visit budget is `4 + floor(reputation / 6)`, capped at 8, so reputation is consumed as the thing that sets how busy a week is. A plant can also only be pitched to the regulars once per week.

**Reason:** The old loop was exploitable — no per-week cap on recommend/restock, restock at 55% of retail, strong sales at price+premium, so buy-restock/spam-recommend printed money, and reputation was written everywhere but read by nothing. Scarcity turns the week into a real choice (sell now, restock, or propagate for later) while staying gentle: refusals are worded warmly and the cap grows as standing grows, rather than punishing.

**Consequence:** `nursery_run_state.gd` owns the visit pool (`week_action_budget`/`has_week_action`/`spend_week_action`), persisted in the save with a migration that opens legacy saves to a full week. Covered by GDScript behavioral tests (`godot/tests/run_tests.gd`) and an `agent-check` guard so the exploit can't quietly return. Reputation now has a felt job; a future system may also spend it directly.
