# Testing And Builds

This project should be difficult to break casually. Every change should pass the same local checks before a PR, and GitHub Actions should prove the same baseline remotely.

## Change Gate

Run this before committing:

```sh
npm test
```

Run this before pushing Godot scene/script changes:

```sh
npm run test:product
```

`npm test` validates repository shape, data catalogs, the Godot scene wiring, the writing pack, and the archived browser prototype. `npm run test:product` adds a real Godot headless import so GDScript parse errors and broken resource loads fail before review.

Playtest build notes for the first vertical slice live in `docs/vertical-slice-0.1-playtest-build.md`.

## Mac Test Path

From the repo root:

```sh
npm test
npm run test:product
npm run godot:run
```

Use `npm run godot:run` for hands-on playtesting in the local Godot editor/runtime. The expected local engine is Godot `4.5.1.stable.official`.

To create the Linux debug build intended for Steam Deck testing:

```sh
npm run export:steamdeck
```

That command requires Godot export templates for `4.5.1.stable` to be installed locally. It writes the build to:

```text
dist/steamdeck/
```

## Steam Deck Test Path

Preferred path for now:

1. Open the latest PR or `main` workflow run in GitHub Actions.
2. Download the `garden-nursery-steamdeck-debug` artifact.
3. Copy the unzipped folder to the Steam Deck.
4. In Desktop Mode, run:

```sh
chmod +x GardenNursery.x86_64
./GardenNursery.x86_64
```

For Gaming Mode testing, add `GardenNursery.x86_64` as a non-Steam game after confirming it launches in Desktop Mode.

## CI Guarantees

GitHub Actions currently runs:

- `npm test`
- Godot headless import
- Steam Deck debug export artifact build

The export job is intentionally a debug build. The goal is not distribution polish yet; the goal is to catch broken exports and make Steam Deck playtest builds routine.

## What This Does Not Cover Yet

- No automated controller navigation test yet.
- No screenshot/layout regression test yet.
- No release signing, notarization, or Steam integration.

Those should be added when the vertical slice has more stable gameplay logic and UI surfaces.
