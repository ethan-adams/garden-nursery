# Godot Project Structure

Use this structure when creating the Godot project.

```text
godot/
  project.godot
  scenes/
    main/
    nursery/
    ui/
  scripts/
    core/
    data/
    ui/
  data/
    plants/
    customers/
    regions/
    dialogue/
  assets/
    art/
      regions/
      plants/
      ui/
      characters/
    audio/
    fonts/
  tests/
```

## Conventions

- Keep simulation logic out of giant scene scripts when possible.
- Prefer small scripts that can be tested or inspected by agents.
- Keep data catalogs in stable, text-friendly files.
- Avoid one enormous all-in-one `.tscn` scene.
- Use clear node names for focus navigation and Steam Deck UI checks.
- Follow `docs/steam-deck-ux-baseline.md` for resolution, text sizing, focus navigation, and input action naming.
- Follow `docs/art-bible.md` and `docs/visual-development-pipeline.md` before adding production-facing visual assets.
- Keep production art source notes or asset briefs close to the work when practical.

## Godot Baseline

Current local version:

```text
4.5.1.stable.official
```

Use `godot --version` to verify.

Do not upgrade the project to a newer Godot minor version without a PR that updates this document, CI, and the roadmap.

## Data Format Bias

The vertical slice now uses JSON catalogs because they are text-friendly, easy for agents to edit, and simple for `npm test` to validate without editor-only tooling.

Current catalogs:

- `godot/data/plants/starter_plants.json` for plant analogues, traits, care, climate fit, price, and starting stock.
- `godot/data/customers/hush_arbor_archetypes.json` for recurring customer archetypes, budgets, garden constraints, taste, contradictions, and embedded market hints.
- `godot/data/regions/hush_arbor.json` for region traits, starting state, market signals, uncertainty, and week outcome rules.
- `godot/data/dialogue/writing_sample_pack.json` for character sketches, customer barks, week reflections, and local events.

GDScript resources remain an option later if editor workflows become more important than raw content editing.

## CI Approach

Local `npm test` remains the default pre-commit entrypoint and validates the static browser sketch, Godot project wiring, data schemas, writing pack shape, and nursery scene text resources.

`npm run test:product` adds a local Godot smoke check and should be used before pushing scene, script, or resource changes.

GitHub Actions also runs a lightweight Godot import check. The CI job downloads the official Godot `4.5.1-stable` Linux binary from the Godot builds release, caches it, then runs:

```sh
godot --headless --path godot --quit-after 1
```

CI also installs the official `4.5.1-stable` export templates and runs the committed `Steam Deck` Linux export preset. This creates a debug artifact for Steam Deck playtesting and catches broken export configuration before merge.

## UI Input Bias

Name input actions by player intent, not hardware. Use `ui_confirm`, `ui_cancel`, `ui_details`, `ui_tab_next`, `ui_tab_previous`, `ui_sort`, and `ui_journal` for controller-friendly UI commands as those surfaces come online.
