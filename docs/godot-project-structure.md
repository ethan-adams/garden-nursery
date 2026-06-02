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

## Godot Baseline

Current local version:

```text
4.5.1.stable.official
```

Use `godot --version` to verify.

Do not upgrade the project to a newer Godot minor version without a PR that updates this document, CI, and the roadmap.

## Data Format Bias

Start with text-friendly data.

Good early options:

- JSON catalogs for plants, customers, regions, dialogue, and market signals.
- GDScript resources if editor workflows become more important.

The first Godot slice should choose whichever option makes agent editing and automated checks easiest.
