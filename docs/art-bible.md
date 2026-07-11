# Garden Nursery Art Bible

This is the visual bar for production art. It should guide every scene, UI surface, prop, plant asset, prompt, and outsourced art brief.

## Visual Target

Garden Nursery should look like a warm botanical field journal brought into a playable 2.5D nursery space.

The target is:

- Painted botanical illustration, not generic farm sim pixel art.
- Clear plant silhouettes with species-specific leaf shapes, flowers, growth habit, and pot/bench scale.
- Tactile nursery materials: wood, soil, seed trays, paper tags, hand-painted signs, twine, galvanized metal, damp stone, glass, canvas shade cloth.
- Region-aware color and weather. Hush Arbor should feel like a temperate valley with orchard culture, roadside stands, mild humidity, and soft practical charm.
- UI inspired by real nursery work surfaces: ledgers, plant tags, market boards, seed packets, drawer labels, order slips, and handwritten notes.

The art should make the player want to browse, inspect, compare, and care for plants.

## First Style Pillars

### Botanical Specificity

Plants must read as living varieties, not green clumps. Each important plant asset needs a visible habit:

- Rosette, vine, upright herb, mounding perennial, cane, shrub, trailing basket, bulb, grass, or young tree.
- Distinct leaf shapes and spacing.
- Clear pot, tray, or soil context.
- A readable health state when the design needs one.

### Useful Warmth

Cozy does not mean beige or blurry. Warmth comes from useful objects, human marks, light, local materials, and the lived-in nursery ritual.

Use:

- Cream paper only as an accent, not the whole UI.
- Earth and green colors balanced with local accent colors.
- Practical clutter that explains gameplay.
- Hand-labeled details where text can remain readable.

Avoid:

- Beige soup.
- Purple-blue fantasy gradients.
- Glossy mobile-game panels.
- Plastic-looking leaves.
- Repeated generic vines as decoration.
- Decorative UI that hides the useful state.

### Steam Deck Readability

At 1280x800, a player should understand the first screen in one glance:

- The player character.
- The main interactable station.
- Inventory or plant stock state.
- Current market or week signal.
- Where focus or action can move next.

Use strong value grouping and silhouettes before surface detail.

## Composition Rules

- Build scenes as playable dioramas with clear foreground, middle interaction plane, and background context.
- Keep gameplay objects readable at normal zoom before adding decorative detail.
- Give each station a strong shape: stand, propagation bench, ledger desk, display table, shade rack, greenhouse door.
- Use labels, color accents, and lighting to support navigation, not to decorate randomly.
- Leave room for controller focus prompts and text panels.

## UI Rules

- UI should feel like a nursery workbench, not a fantasy RPG menu.
- Use restrained panels with paper, wood, enamel tag, chalkboard, or ledger references.
- Buttons must be readable without hover.
- Important state should use text plus shape/color/icon, not color alone.
- Use plant tags, seed packets, market boards, and ledgers as interaction metaphors only when they improve clarity.
- Do not put instructional flavor text in the UI just to explain features. The controls themselves should be clear.

## Palette Direction

Hush Arbor base:

- Leaf greens: sage, herb green, deep ivy, new growth.
- Soil and material: umber, bark, damp dark earth, galvanized gray, weathered wood.
- Light: warm morning yellow, soft overcast blue-gray, pale greenhouse glass.
- Accents: orchard red, seed-packet teal, marigold, hand-painted sign blue.

Every major screen needs at least one non-green/non-brown accent family so it does not collapse into mud.

## Asset Bar

An asset is not production-ready until it passes these checks:

- It matches this art bible and the relevant asset brief.
- It is readable at Steam Deck target resolution.
- It has a transparent or intentionally designed background when used as a sprite.
- It has no obvious AI artifacts, warped text, extra limbs, melted leaves, inconsistent light, or broken perspective.
- It is named and organized for reuse.
- It has been seen in the actual Godot scene where it will ship.

## Source And Rights Rule

Do not add third-party art unless the license is explicit and compatible with the repo. Record the source, license, and any required attribution in the asset brief or a colocated note.

AI-generated art is allowed for prototypes, but production candidates need prompt, seed/tool/version when available, cleanup notes, and in-engine acceptance screenshots.
