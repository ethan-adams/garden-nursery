# Vertical Slice Save Format

The Godot vertical slice writes a simple JSON save to:

`user://garden_nursery_vertical_slice_save.json`

The current format id is `garden-nursery.save.v1`.

## Saved State

- `week`, `cash`, and `reputation`
- `selected_signal_index` and `selected_plant_id`
- `inventory_stock`, keyed by plant id
- `propagation_tray`, copied from the active bench tray state
- `customer_notes`, keyed by recurring customer id
- `discoveries`
  - `plants`
  - `customers`
  - `signals`
- `week_reflections`, the latest ledger-written journal reflections
- `weekly_activity`, used by the ledger if the player quits before closing the week

## Load Behavior

The stand overlay attempts to load the save after base Hush Arbor data is loaded. Missing, malformed, empty, or mismatched-format saves leave the game in a fresh run and add a short nursery log note when useful.

The save is intentionally local to the current UI-owned vertical slice. Issue `#42` can move this into a dedicated simulation state owner without changing the visible player contract.

## Reset Behavior

The `Reset Run` header action removes the current save, reloads starter Hush Arbor data, and immediately writes a clean new-run save for testing.
