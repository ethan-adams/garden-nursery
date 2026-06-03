# Decisions

Agents append to this file when a decision changes how the project is built, tested, structured, or designed. Do not rewrite old entries except to fix clear factual errors.

## 2026-06-03 - Product checks protect Godot first

**Decision:** The standard change gate is `npm test`, with `npm run test:product` required for Godot scene or script changes.

**Reason:** The browser prototype is disposable. The product is the Godot vertical slice, and GDScript/resource errors need to fail before PR review.

**Consequence:** Local checks stay fast, while product-impacting changes have a stronger opt-in check that requires Godot on `PATH`.

## 2026-06-03 - Steam Deck builds are Linux debug exports

**Decision:** Steam Deck playtest builds use the committed `Steam Deck` Godot export preset and `npm run export:steamdeck`.

**Reason:** Steam Deck runs Linux well, and a standard export artifact is easier to test repeatedly than asking each tester to run the Godot editor.

**Consequence:** Export templates are now part of the build process. CI installs them, and local machines need them installed for local exports.
