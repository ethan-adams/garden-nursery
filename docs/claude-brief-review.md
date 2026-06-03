# Claude Brief Review

The Claude brief has useful instincts, but it is stale against the current repo.

## Useful

- It correctly pushes for stronger process docs, explicit data validation, and a standard testing path.
- Moving the browser prototype out of the root is a good call. It prevents agents from confusing the old sketch with the real Godot product.
- The week-loop outline is directionally useful: explicit close-week pacing, propagation queue, rolling market signals, and customer outcomes are the right next systems.
- The hybrid bench questions are worth turning into decisions before plant genetics hardens.
- The game-feel references are useful as implementation filters, even though they should not replace the existing creative direction.

## Stale Or Wrong

- `docs/roadmap.md` already exists and is better than the proposed table-only version.
- The proposed `data/plants.json` path conflicts with the chosen Godot catalog structure under `godot/data/`.
- The suggested real-world Northeast plant set clashes with Hush Arbor as a fictional starter region. The facts are useful inspiration, not canonical content.
- Issue templates already exist, though they needed stronger `Done when` language.
- The writing/Hush Arbor concern was already partially addressed by `docs/starter-region-brief.md` and `docs/writing-sample-pack.md`.

## How To Use It

Do not paste the brief in wholesale. Mine it for next-ticket scope:

- Propagation queue and close-week state.
- Customer-specific sold/unsold/discovery outcomes.
- Hybrid bench decisions.
- Game-feel guardrails.
- Stronger automated checks when data and scene scripts change.
