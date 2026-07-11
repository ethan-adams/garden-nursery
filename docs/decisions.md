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

## 2026-07-10 - Self-playtest harness: the game verifies itself

**Decision:** The project drives and observes the real game in CI instead of leaving felt correctness to a human launching the build (issue #98). Two complementary layers, both wired into the pipeline. Tier 1: `godot/tests/run_tests.gd` gained an async runner that mounts the real overlay in the SceneTree at 1280x800, awaits layout, drives it (focus, recommend, advance), and asserts *observable* state — scroll-follows-focus by geometry, focused controls staying on screen, the flow moving the run forward. It runs under `npm run test:product`. Tier 2: `godot/tools/capture_screens.gd` (+ `npm run godot:screens`, a non-gating xvfb CI job) renders the yard and stand at 1280x800 and saves PNGs the harness reads back to judge layout; the screenshots ship with the artifact and in every ship report.

**Reason:** Structural checks ("the scene contains a ScrollContainer") and a boot smoke can't tell whether the game actually plays right, so every UI/gameplay change fell to Ethan to eyeball — the bottleneck the harness is meant to remove. The two layers catch different bug classes: the geometry tests prove reachability, the screenshots catch what a player's eye catches. This earned its keep immediately — the first screenshot run surfaced a horizontal-overflow bug that clips left-column text off screen at 1280px in some weeks, invisible to the passing focus tests (filed separately).

**Consequence:** Behavioral scene tests and the capture tool are guarded by an `agent-check` so a future refactor can't quietly delete them. Screenshots are evidence, not a gate: the CI job is `continue-on-error` and outside the auto-revert boundary, so a flaky virtual-framebuffer frame never reverts `main`. Ship reports for UI/gameplay work include a screenshot strip. Subjective Deck-in-hand feel stays Ethan's, but is offered as screenshots rather than "go launch a build."

## 2026-07-10 - Visual craft-pass now, painted botanical art later

**Decision:** Ethan judged the running build "gross" and demotivating; screenshots confirmed the game violated its own art bible (translucent hex plaques burying the painted stations, a centered default-theme tutorial slab, debug-looking path lines, and a dark translucent stat dashboard for the stand). The fix is a two-layer strategy chosen with Ethan: (1) an immediate in-engine craft-pass in a committed flat-illustration style — repainted yard SVG (morning light, blossoming orchard, striped stand awning, plant-forward beds, painted sign planks per station, a real journal station object), diegetic sign Labels instead of floating chips, a project-wide workbench UI theme (`godot/assets/ui/nursery_theme.tres`: opaque paper/kraft/slate/wood panels, marigold controller-focus ring, orchard-red primary action), and a bottom-docked onboarding note; (2) painted botanical art arrives later through per-asset briefs and slots into the same scenes — nothing from the craft-pass is throwaway.

**Reason:** The old look wasn't a missing-assets problem but a missing-craft problem: one hazy background SVG plus default Godot chrome, with readability markers layered on top instead of drawn into the world. A craft-pass is free, ships immediately, and every hour of it (theme, layout, signage, composition) survives a later art upgrade; jumping straight to generated painted assets would have blocked on Ethan's image-gen time while the game stayed ugly.

**Consequence:** SVGs are the editable art source; `godot/tools/rasterize_art.gd` regenerates the committed PNGs (import-pipeline rule unchanged). UI text is Alegreya/Alegreya Sans (SIL OFL 1.1, license texts committed beside the fonts). Because the project now loads a custom gui theme at engine boot — before a single-pass export imports its fonts — `scripts/export-godot.mjs` runs a `--import` pass first; the first ship attempt was auto-reverted when the fresh-checkout export aborted on the unimported theme, and fixed forward here. The week-outcome header overflow (filed from the first screenshot run) is fixed by moving visits into a stats box and trimming the region line. `agent-check` now guards the theme wiring, font licenses, sign-label layer, the rasterizer/SVG sources, and the export import-pass in place of the old hex-chip assertions. The stand overlay stays a full-screen surface for now; making it feel more like standing at a market table is future product work, not theme work.

## 2026-07-11 - Fast-ship: relax the delivery ceremony, tolerate a red main

**Decision:** The delivery contract moves to "fast-ship." The multi-agent review gate is no longer run on every ship — it's opt-in for genuinely risky, large, or architectural changes (new systems, save-format changes, broad refactors) or on request; ordinary work goes commit → verify locally → push → keep moving. The harness no longer blocks watching CI to completion: a task is complete once it's locally verified and pushed. CI still re-verifies async and auto-reverts a red head (kept on — a broken main self-heals), but a red main is now an acceptable cost of speed, not an incident; if a push is reverted, the harness picks it up next turn or fixes forward. The fast local gates (`npm test`, `test:product` for `godot/`, drive-the-game + `godot:screens` for UI/gameplay) are explicitly kept — they're cheap and are what let the harness ship unsupervised. `agent-check.mjs` assertions are demoted from a wall to a convenience: an assertion that fights an intentional change gets updated or deleted in the same commit.

**Reason:** Ethan wants to unblock the harness to work faster without per-ship guidance, and judged the ceremony too heavy for a personal project where breaking main is cheap. The evidence backed it: across the visual craft-pass ship, the cheap checks (npm test, the screenshot harness, the CI Steam Deck export) caught every real problem — the header overflow and the fresh-checkout export failure — while the multi-agent review gate (~20 agents, ~680k tokens, ~9 min) surfaced only three minors. The expensive gate wasn't earning its per-ship cost.

**Consequence:** `CLAUDE.md` rewritten (intro, Delivery Contract, Verification, Multi-Agent Orchestration) to describe fast-ship. Speed is the default; the review fleet is a tool reached for deliberately, not a tollgate. Guardrails that are about product identity or safety (the CLAUDE.md "stop and ask" list, Product Guardrails) are unchanged — this relaxes process ceremony, not the boundaries on what the game is.
