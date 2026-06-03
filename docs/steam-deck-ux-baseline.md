# Steam Deck UX Baseline

Garden Nursery is Steam Deck-first. Desktop keyboard and mouse can work, but the Godot vertical slice should be comfortable at 1280x800 with controller navigation before it depends on pointer precision.

## Target Resolution

- Primary design target: 1280x800, matching the Steam Deck's 16:10 screen.
- Godot viewport baseline: `window/size/viewport_width=1280` and `window/size/viewport_height=800`.
- Stretch policy: keep UI authored for the 1280x800 baseline and expand outward on larger displays.
- Safe content area: leave at least 44 px vertical and 56 px horizontal breathing room around core UI at 1280x800.
- Avoid layouts that require hover, tiny drag targets, or dense spreadsheet-style inspection.

## Text Sizing

- Body text should start at 20 px or larger in Godot UI.
- Secondary labels, counters, and tags should stay at 18 px or larger unless they are decorative.
- Primary screen titles can use 36-44 px when there is enough room.
- Favor short, specific labels over compressed text. If a phrase must wrap, design the container for two readable lines.
- Do not rely on color alone for important state; pair color with text, iconography, position, or focus state.

## Focus Navigation

- Every playable command must be reachable without a mouse.
- Use visible focus states for all buttons, list rows, tabs, cards, and actionable plant/customer items.
- Prefer simple directional focus order that matches the visible layout: left to right, top to bottom.
- Do not hide essential information behind hover. Tooltips may exist, but the same information must be reachable through focus or an explicit details view.
- Keep repeated UI patterns stable so D-pad movement is predictable between inventory, customers, market hints, and end-of-week results.
- Modal screens should focus their safest primary action on open and return focus to the invoking control when closed.

## Input Actions

Use semantic action names instead of binding gameplay directly to device buttons. Start with these conventions:

- `ui_confirm`: primary accept, select, buy, sell, or continue.
- `ui_cancel`: back, close, decline, or leave a modal.
- `ui_details`: inspect a focused plant, customer, market hint, or result.
- `ui_tab_next` and `ui_tab_previous`: move between major panels or tabs.
- `ui_sort`: cycle sorting/grouping for inventory and market lists.
- `ui_journal`: open the journal, ledger, or notes surface.

Godot's built-in directional actions (`ui_up`, `ui_down`, `ui_left`, `ui_right`) should remain the default navigation layer. Add keyboard and controller bindings for new semantic actions when the relevant UI exists, and document any temporary keyboard-only action in the PR that introduces it.

## Current Automated Checks

`npm test` can currently verify:

- The Godot project targets a 1280x800 viewport.
- The stretch settings are present.
- The main scene has a full-screen `Control` root.
- The Steam Deck UX baseline doc exists and names resolution, text sizing, focus navigation, input actions, and manual checks.

## Manual Checks Later

As the slice becomes playable, PRs that touch UI should manually verify:

- Text is readable at 1280x800 on a Steam Deck-like viewport.
- All screens can be navigated with keyboard/controller focus.
- Focus states are visible in normal and disabled states.
- No required command depends on hover or mouse precision.
- Common actions take a reasonable number of button presses.
- Suspend/resume or window refocus does not strand the player in an unusable state.

## First Slice Implications

The first roadside nursery stand should be organized as a few predictable focus zones:

- Market signals.
- Plant inventory.
- Customer request/details.
- Recommendation or sale actions.
- Week summary and next-week controls.

This keeps the opening learnable while still supporting the larger market-reading loop.
