# Engine Stack Research

## Recommendation

Use **Godot 4.x with GDScript** for the real game.

Keep the current browser prototype only as a disposable design sketch until the first Godot slice exists. After that, migrate gameplay ideas into Godot and remove or archive the JavaScript prototype.

## Why Godot Fits This Game

Garden Nursery is most likely a 2D cozy management/sim game with lots of UI, plant data, scene composition, and iterative systems. The engine should be easy for an agent to edit, easy for the user to learn, and friendly to Git-based PR workflows.

Godot is the best default because:

- It is strong for 2D games and UI-heavy prototypes.
- Project files and scene files are text-based enough for agents and Git to inspect.
- GDScript is small, readable, and close to the engine's mental model.
- The editor is lightweight compared with Unity.
- It is open source and avoids licensing/account friction.
- It has command-line support for headless runs and exports, which gives us a path to CI checks.

## Shortlist

### Godot 4.x + GDScript

Best fit for this project.

Pros:

- Good 2D and UI workflow.
- Text scene format helps with version control.
- Lightweight install and project structure.
- GDScript is readable for learning and agent edits.
- Command-line/headless usage supports automation.

Cons:

- GDScript test tooling is less standardized than web/Rust test tooling.
- Scene files can still be awkward to merge if many agents edit the same scene.
- We will need to design a repo harness around Godot-specific checks.

Harness implication:

- Keep simulation logic in scripts/resources that can be exercised by command-line test runners.
- Keep scenes small and avoid giant all-in-one `.tscn` files.
- Add a CI job once we decide how to install/run Godot in GitHub Actions.

### Unity 6 + C#

Strong engine, but heavier than this project needs right now.

Pros:

- Mature tooling, asset pipeline, docs, and ecosystem.
- C# is excellent for testable simulation code.
- Strong long-term commercial path.

Cons:

- Heavier editor and project metadata.
- More licensing/account/tooling surface area.
- Less pleasant for small autonomous text-first iteration.

Use Unity if the project becomes asset-store-heavy, 3D-heavy, or we decide C# architecture matters more than lightweight iteration.

### Bevy + Rust

Technically elegant, but probably not the learning/productivity sweet spot.

Pros:

- ECS is a great fit for systemic simulations.
- Rust code is very testable.
- Excellent for agentic code review and clean architecture.

Cons:

- Higher learning curve.
- Editor/story/UI workflows are much less mature than Godot or Unity.
- The game could become an engine/tooling project before it becomes a nursery game.

Use Bevy if the main goal becomes learning Rust/ECS and building a simulation-first engine.

### Defold + Lua

Interesting lightweight 2D option, but less ideal than Godot here.

Pros:

- Lightweight and focused.
- Lua is approachable.
- Good for 2D and web/mobile deployment.

Cons:

- Smaller ecosystem and less obvious fit for UI-heavy management sim tooling.
- Godot has a stronger all-around editor workflow for this concept.

Use Defold if we want a very small Lua-driven 2D engine and are willing to accept a smaller ecosystem.

## Proposed Stack

- Engine: Godot 4.x
- Language: GDScript first
- Data: Godot resources or JSON for plant/customer catalogs
- Art style: 2D, cozy, hand-built UI; placeholder vector/pixel assets at first
- Repo workflow: PR-first, branch protection, `npm test` until Godot checks replace or supplement it
- Future CI: add a Godot sanity job that imports the project and runs test scenes/scripts headlessly

## Migration Plan

1. Keep the current web prototype as a reference.
2. Add a minimal Godot project in a task branch.
3. Build one playable Godot slice:
   - Main nursery screen.
   - Plant inventory list.
   - Weekly market trend.
   - Sell one plant.
   - Advance one week.
4. Add a Godot-oriented sanity check to the harness.
5. Once the Godot slice is playable, move roadmap language from "browser prototype" to "Godot prototype."
6. Archive or remove the JavaScript prototype when it no longer teaches us anything.

## Open Questions

- Should the first Godot version be pure 2D UI, or include a small spatial nursery floor from the beginning?
- Should plant/customer data live in JSON for easy AI editing, or as Godot resources for editor friendliness?
- Should we use GDScript only, or reserve C# for deeper simulation code later?

## Sources

- Godot documentation: platform support and command-line/headless workflows.
- Godot documentation: `.tscn` scene files are text and version-control friendly.
- Unity documentation: Unity 6 release/support model and LTS guidance.
- Bevy documentation: app logic uses ECS, with components and systems as the core model.
- Defold documentation: game logic is written in Lua scripts attached to game objects/GUI/render components.
