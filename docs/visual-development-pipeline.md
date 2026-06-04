# Visual Development Pipeline

Garden Nursery needs a repeatable art pipeline, not one-off generated assets. This pipeline is for agents and humans making visual work.

## Research Takeaways

Current game-art pipeline guidance is consistent on a few points:

- Pre-production should define the visual style, references, scope, and asset needs before production art begins.
- A style guide or art bible is needed to keep assets coherent across contributors and time.
- Concept work should explore multiple directions cheaply before committing to final assets.
- Production assets need review, integration, and testing in the game engine, because an image that looks good alone can fail at gameplay scale.
- AI can accelerate ideation and variations, but consistency still depends on explicit references, repeatable prompts, human cleanup, and in-engine validation.

For this repo, that means future visual work must move through brief, references, style target, asset pass, Godot integration, and Steam Deck readability checks.

Sources used:

- Pixune, "Game Art Pipeline Explained: Game Art Production Workflow" - frames game art around pre-production, production, post-production, visual direction, research, asset lists, and engine integration.
- Pixune, "A Complete Guide to 2D Game Art Pipeline" - calls out 2D pre-production style decisions, concept art as workflow guidance, and import checks for aspect ratio, resolution, and pixel quality.
- VSQUAD, "2D Game Art Styles: Unit Design & Production Guide" - describes moving from brief/style guide to final assets and checking final assets in-engine at real scale and lighting.
- The Art Bible project - summarizes art bibles/style guides as a consistency tool across production.
- Layer, "IP-Consistent AI Generation for Game Studios" - reinforces that AI-assisted asset work needs explicit style consistency workflows, not isolated prompts.

## Pipeline Stages

### 1. Visual Brief

Before creating or replacing production-facing art, write a short asset brief from `docs/art-asset-brief-template.md`.

The brief must define:

- Gameplay job.
- Scene or UI location.
- Region and season.
- Style references.
- Required dimensions or Godot use.
- Readability needs.
- Source/license plan.
- Acceptance checks.

For tiny placeholder-only edits, a commit message note is enough. For anything meant to set style, create the brief.

### 2. Reference Board

Gather references before producing assets. Use references for analysis, not copying.

Minimum reference set for a major scene or UI pass:

- 3 botanical or plant-form references.
- 3 material/setting references.
- 2 UI or layout references when UI is involved.
- 1 negative reference showing what to avoid.

Record links or local filenames in the brief. If using online references, prefer museum, nursery, botanical garden, manufacturer, or public-domain sources over anonymous image dumps.

### 3. Style Exploration

Create 3-6 small explorations before final production:

- Shape/silhouette test.
- Value grouping test.
- Palette test.
- Material texture test.
- Optional AI-generated mood pass.
- Optional hand cleanup or paintover pass.

Do not polish the first idea. Pick a direction based on gameplay readability and fit with `docs/art-bible.md`.

### 4. Asset Production

Production assets should be made in layers or editable source form when practical.

Preferred source formats:

- SVG for simple icons, signs, tags, and layout mockups.
- Layered raster source when a painting tool is used.
- PNG/WebP runtime exports for Godot.
- JSON catalogs for data-driven plant identity, separate from art files.

Name files by use, not mood:

```text
godot/assets/art/regions/hush_arbor/stations/propagation_bench_day.png
godot/assets/art/plants/hush_arbor/moonmint_seedling.png
godot/assets/art/ui/plant_tag_common.png
```

### 5. Godot Integration

Every production candidate must be tested in the scene where players will see it.

Check:

- 1280x800 Steam Deck target.
- Controller focus does not cover important art.
- Text remains readable.
- Asset scale matches adjacent objects.
- Interactables are visually distinct.
- Color contrast works in normal and dim scene lighting.
- The asset does not make the scene feel like a collage of different styles.

### 6. Art Review

Review against the art bible before merge.

Reject or revise if:

- The asset is generic cozy farm art.
- Plant forms are indistinct.
- The scene is dominated by beige, brown, or a single green family.
- UI styling fights usability.
- The asset only looks good when viewed outside the game.
- AI artifacts are visible at gameplay scale.

### 7. Capture And Archive

For major visual changes, keep at least one screenshot or exported image in a documented location when practical. The goal is to make style evolution inspectable by future agents.

Recommended paths:

```text
docs/visual-references/
docs/visual-references/hush-arbor-first-yard/
```

Do not commit huge moodboard dumps. Keep only useful, rights-safe references or small review captures.

## AI-Assisted Art Rules

AI image generation can be used for:

- Mood exploration.
- Palette exploration.
- Fast prop or scene thumbnails.
- Texture inspiration.
- Placeholder drafts when clearly labeled.

AI output is not automatically production art.

Before shipping AI-assisted assets:

- Remove or repaint visible artifacts.
- Ensure all text is manually authored or replaced in-engine.
- Keep prompts/settings when available.
- Verify the asset in Godot at 1280x800.
- Make sure the final result matches Garden Nursery rather than the generator's default style.

## Agent Workflow

When a task mentions art, graphics, visual design, UI style, scene dressing, icons, or asset replacement:

1. Read `docs/art-bible.md`.
2. Read this pipeline.
3. Inspect the target scene and existing assets.
4. Create or update an asset brief for production-facing work.
5. Produce the smallest complete visual slice.
6. Integrate it in Godot.
7. Run `npm test`.
8. Run `npm run test:product` when Godot scenes/scripts/resources changed.
9. Include manual or screenshot verification notes in the PR.

## Immediate Direction

The current art should be treated as prototype scaffolding. The first serious visual target should be a Hush Arbor nursery yard style frame that proves:

- Plant silhouettes are specific and appealing.
- The roadside stand, propagation bench, and market board are readable.
- The UI feels like a practical nursery workbench.
- The palette is warm but not beige.
- The result still works at 1280x800 with controller-first UI.
