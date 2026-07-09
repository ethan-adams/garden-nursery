# Hush Arbor Station Readability Brief

## Gameplay Job

Make the five yard stations read by shape and context before the player relies on prompt text.

## Scene Location

`godot/scenes/nursery/nursery_yard.tscn`

## Region And Season

Hush Arbor, early spring into damp local weather.

## Style Target

- Painted botanical field-journal practicality.
- Weathered wood, paper tags, seed-packet teal, orchard red, ledger cream, shade-cloth green.
- Clear silhouettes: posted board, plant table, tray bench, ledger crate, notebook.

## Asset Plan

Use editable Godot scene primitives as a first production-readable pass:

- Colored ground plaques behind each station.
- Short station labels using nursery-material colors.
- Distinct accent color per station so the player can scan the yard.

No third-party art is used.

## Acceptance Checks

- Stations are visually distinct at 1280x800.
- Prompt text does not cover the main silhouette.
- Palette stays Hush Arbor: plant-forward, warm, damp, not generic fantasy farm.
- `npm test` and `npm run test:product` pass.
