# Godot Vertical Slice 0.1 Playtest Build

Build point: merge commit for issue `#41` on `main`.

Artifact source: the GitHub Actions `Sanity` workflow run for that commit.

Download artifact: `garden-nursery-steamdeck-debug`

Inside the unzipped artifact, run:

```sh
chmod +x GardenNursery.x86_64
./GardenNursery.x86_64
```

## Controls

- Move: directional input through Godot `ui_up`, `ui_down`, `ui_left`, `ui_right`
- Interact/select: `E`, Space, or gamepad south button
- Close/back: Escape or gamepad east button
- Focus next/previous where available: Page Down / shoulder buttons

## What To Test

- Walk the Hush Arbor yard and open each station: signal board, plant stand, propagation bench, ledger, and discovery journal.
- Recommend several plants and confirm different customers react differently.
- Start a propagation tray, close at least one week, and read the ledger.
- Quit and reopen the build after changing state; the run should auto-load.
- Use `Reset Run` and confirm the starter state returns.

## Known Limitations

- The simulation state still lives in the stand overlay; issue `#42` should extract it into a dedicated state owner.
- Controller focus is basic and has no automated navigation test yet.
- The Steam Deck export is a debug artifact, not a signed release build.
- The journal is text-first and uses discovered notes rather than a full notebook UI.
- Save data is local JSON with no migration layer yet.

## Feedback Needed

- Which station feels most confusing on a first pass?
- Do recommendation outcomes explain customer needs clearly enough?
- Does the ledger explain why the week changed cash, reputation, and inventory?
- Is text readable at 1280x800 on Steam Deck?
- Does save/load behave as expected after closing and reopening?
