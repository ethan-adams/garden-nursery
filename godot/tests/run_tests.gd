extends SceneTree

# Minimal headless GDScript test runner.
#
# Run with: godot --headless --path godot -s res://tests/run_tests.gd
# (wrapped by `npm run godot:test`).
#
# Each test is a method named `test_*`. It records failures via `expect(...)`.
# The process exits non-zero if any expectation fails, so CI catches regressions
# in real GDScript behavior. Issue #98 will grow this into a full multi-week
# playthrough harness; keep additions small and readable.

const NurseryRules = preload("res://scripts/core/nursery_rules.gd")
const NurseryRunState = preload("res://scripts/core/nursery_run_state.gd")
const StandScene = preload("res://scenes/nursery/nursery_stand.tscn")
const SAVE_PATH := "user://garden_nursery_vertical_slice_save.json"
# The Steam Deck design target. Headless defaults the window to a square, so scene tests
# force this size to assert layout against the real 1280x800 constraint, not a taller one.
const DECK_SIZE := Vector2i(1280, 800)

# Scene-driven tests are async: they add the real overlay to the tree, await frames so
# `_ready`/`@onready`/container layout settle, drive it, then assert observable state.
# List them here explicitly (they must be awaited); the `test_*` methods below stay
# synchronous pure-logic checks that never touch the tree.
const SCENE_TESTS := [
	"scene_test_scroll_follows_focus_into_view",
	"scene_test_every_section_anchor_stays_on_screen",
	"scene_test_stand_content_never_overflows_viewport",
	"scene_test_recommend_and_advance_drive_run_state",
]

var _failures: Array[String] = []
var _current := ""
var _test_count := 0

# Build a run state from the real shipped catalogs, the same way nursery_stand.gd does,
# so tests exercise actual game data rather than fixtures that can drift from it.
func _fresh_run_state() -> NurseryRunState:
	var rs := NurseryRunState.new()
	var region: Dictionary = _read_json("res://data/regions/hush_arbor.json")
	var dialogue: Dictionary = _read_json("res://data/dialogue/writing_sample_pack.json")
	var plants: Array = _read_json("res://data/plants/starter_plants.json").get("plants", [])
	var customers: Array = _read_json("res://data/customers/hush_arbor_archetypes.json").get("customers", [])
	rs.setup(plants, customers, region, dialogue)
	return rs

func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed

func _in_stock_plant_ids(rs: NurseryRunState) -> Array:
	var ids := []
	for plant in rs.plants:
		if int(plant.get("starting_stock", 0)) > 0:
			ids.append(plant.get("id", ""))
	return ids

# SceneTree entrypoint. `_initialize` can't await, so it kicks off the async runner and
# returns; the main loop then ticks `process_frame`, resuming the coroutine until it
# quits.
func _initialize() -> void:
	_run()


func _run() -> void:
	_run_sync_tests()
	await _run_scene_tests()
	if _failures.is_empty():
		print("ok - %d GDScript test(s) passed" % _test_count)
		quit(0)
	else:
		for failure in _failures:
			printerr("FAIL - %s" % failure)
		printerr("%d assertion(s) failed" % _failures.size())
		quit(1)


func _run_sync_tests() -> void:
	var tests := []
	for method in get_method_list():
		var name: String = method.get("name", "")
		if name.begins_with("test_"):
			tests.append(name)
	tests.sort()
	for name in tests:
		_current = name
		_test_count += 1
		call(name)


func _run_scene_tests() -> void:
	for name in SCENE_TESTS:
		_current = name
		_test_count += 1
		await call(name)


# Add the overlay to the tree at the 1280x800 target, wait for `_ready`/`@onready` and a
# couple of layout passes to settle, then hand it back sized and ready to drive. The
# caller frees it. A stale save is cleared first so every run starts from a fresh week.
func _mount_stand() -> Control:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	root.size = DECK_SIZE
	var stand := StandScene.instantiate() as Control
	root.add_child(stand)
	# Let `_ready` fire and `@onready` refs resolve before driving the overlay. The scene
	# root already carries full-rect anchors, so it fills the 1280x800 window on its own —
	# don't override its anchors, which would shift the SafeArea margins off true.
	await _settle(1)
	stand.open_station("all")
	await _settle()
	return stand


func _settle(frames: int = 3) -> void:
	for _i in range(frames):
		await process_frame

func expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append("%s: %s" % [_current, message])

# --- nursery_rules.best_outcome_for (issue #91) ---

func test_best_outcome_requires_a_trait_match() -> void:
	var outcomes := [
		{"id": "read_frost", "trigger_traits": ["hardy", "early-spring"], "cash_bonus": 18, "reputation_bonus": 3},
		{"id": "shade_porches", "trigger_traits": ["shade", "porch-friendly"], "cash_bonus": 14, "reputation_bonus": 4},
	]

	# A plant whose traits match no outcome earns nothing.
	var mismatched := {"id": "p1", "traits": ["tender", "warmth-loving"]}
	var none := NurseryRules.best_outcome_for(mismatched, outcomes)
	expect(none.is_empty(), "a plant with no matching traits must yield an empty outcome")
	expect(int(none.get("cash_bonus", 0)) == 0, "empty outcome must pay no cash")
	expect(int(none.get("reputation_bonus", 0)) == 0, "empty outcome must pay no reputation")

	# No selected plant (empty dictionary) also earns nothing.
	var unselected := NurseryRules.best_outcome_for({}, outcomes)
	expect(unselected.is_empty(), "closing a week with no selected plant must yield an empty outcome")

	# A genuine trait match still wins so real activity is rewarded.
	var matching := {"id": "p2", "traits": ["hardy", "early-spring"]}
	var earned := NurseryRules.best_outcome_for(matching, outcomes)
	expect(earned.get("id", "") == "read_frost", "a matching plant must earn its outcome")

# --- art travels through the import pipeline (issue #92) ---
# The yard and player sprites must carry imported Texture2D resources set in the
# scene, not load image files at runtime. Runtime Image.load_from_file works in the
# editor but silently fails from an exported PCK, leaving a gray void. Instancing the
# scene (without adding it to the tree, so _ready never fires) and asserting the
# texture resolved proves the ext_resource is a real imported resource that the
# exporter packs.

func test_yard_sprite_has_imported_texture() -> void:
	var scene: PackedScene = load("res://scenes/nursery/nursery_yard.tscn")
	expect(scene != null, "nursery_yard.tscn must load")
	if scene == null:
		return
	var yard := scene.instantiate()
	var sprite := yard.get_node_or_null("YardArt") as Sprite2D
	expect(sprite != null, "YardArt node must exist")
	expect(sprite != null and sprite.texture != null, "YardArt must carry an imported texture, not load one at runtime")
	yard.free()

func test_player_sprite_has_imported_texture() -> void:
	var scene: PackedScene = load("res://scenes/player/player.tscn")
	expect(scene != null, "player.tscn must load")
	if scene == null:
		return
	var player := scene.instantiate()
	var sprite := player.get_node_or_null("GardenerSprite") as Sprite2D
	expect(sprite != null, "GardenerSprite node must exist")
	expect(sprite != null and sprite.texture != null, "GardenerSprite must carry an imported texture, not load one at runtime")
	player.free()

# --- weekly action economy (issue #93) ---

func test_week_action_budget_scales_with_reputation() -> void:
	var rs := NurseryRunState.new()
	rs.reputation = 0
	expect(rs.week_action_budget() == NurseryRunState.WEEK_ACTION_BASE, "a quiet stand gets the base visit budget")
	rs.reputation = NurseryRunState.WEEK_ACTION_REPUTATION_STEP
	expect(rs.week_action_budget() == NurseryRunState.WEEK_ACTION_BASE + 1, "reputation buys extra visits, one step at a time")
	rs.reputation = 10_000
	expect(rs.week_action_budget() == NurseryRunState.WEEK_ACTION_MAX, "the visit budget is capped so it can't re-open an infinite loop")
	rs.reputation = -50
	expect(rs.week_action_budget() == NurseryRunState.WEEK_ACTION_BASE, "a poor reputation never drops below the base budget")

func test_week_actions_are_limited_and_refresh_on_close() -> void:
	var rs := _fresh_run_state()
	var allowance: int = rs.week_action_allowance
	expect(allowance > 0, "a fresh week grants at least one visit")
	var stocked := _in_stock_plant_ids(rs)
	expect(stocked.size() > allowance, "need more in-stock plants than the allowance to exhaust it on distinct plants")

	# Spend the whole allowance on distinct in-stock plants.
	for i in range(allowance):
		rs.recommend_plant(stocked[i])
	expect(rs.week_actions_remaining == 0, "recommending distinct plants spends the week's visits down to zero")

	# One more recommendation, on a not-yet-pitched plant, is refused with no cash change.
	var cash_before: int = rs.cash
	var blocked := rs.recommend_plant(stocked[allowance])
	expect(String(blocked.get("outcome_text", "")).contains("visits are spent"), "recommending past the limit is gently refused")
	expect(rs.cash == cash_before, "a refused recommendation must not move cash")

	# Closing the week refreshes the pool.
	rs.advance_week()
	expect(rs.week_actions_remaining == rs.week_action_allowance, "closing the week reopens the stand's visits")

func test_restock_recommend_arbitrage_is_closed() -> void:
	var rs := _fresh_run_state()
	rs.cash = 10_000  # plenty of cash, so only the action economy can stop a loop
	var stocked := _in_stock_plant_ids(rs)
	expect(stocked.size() > 0, "need an in-stock plant")
	var plant_id: String = stocked[0]

	# First pitch of the plant works and spends a visit.
	rs.recommend_plant(plant_id)

	# The old exploit: restock the same plant and re-pitch it in the same week.
	rs.selected_plant_id = plant_id
	rs.restock_selected_plant()
	var cash_before_repitch: int = rs.cash
	var repitch := rs.recommend_plant(plant_id)
	expect(String(repitch.get("outcome_text", "")).contains("already had its turn"), "the same plant can't be re-pitched the same week")
	expect(rs.cash == cash_before_repitch, "a blocked re-pitch earns nothing — the buy-restock/spam-recommend loop is closed")

func test_restock_and_propagation_gate_on_the_week_budget() -> void:
	var rs := _fresh_run_state()
	rs.cash = 10_000  # cash is never the blocker here — only the visit budget is
	var stocked := _in_stock_plant_ids(rs)
	expect(stocked.size() > 0, "need an in-stock plant")

	# Pick a plant that can actually propagate, so the visit gate (not a missing profile)
	# is what stops it.
	var propagatable := ""
	for id in stocked:
		if not rs.propagation_profile(rs.find_plant(id)).is_empty():
			propagatable = id
			break
	expect(propagatable != "", "need a plant with a propagation profile")
	rs.selected_plant_id = propagatable

	# Spend the week down to zero visits.
	rs.week_actions_remaining = 0

	var restock := rs.restock_selected_plant()
	expect(String(restock.get("outcome_text", "")).contains("visits are spent"), "restock is refused when the week's visits are spent")
	var prop := rs.start_propagation()
	expect(String(prop.get("outcome_text", "")).contains("visits are spent"), "starting a tray is refused when the week's visits are spent")
	expect(rs.propagation_trays.is_empty(), "no tray is created once visits are spent")

func test_action_economy_survives_save_load() -> void:
	var rs := _fresh_run_state()
	var stocked := _in_stock_plant_ids(rs)
	rs.recommend_plant(stocked[0])
	var remaining: int = rs.week_actions_remaining
	var snapshot := rs.save_state_snapshot()

	var restored := _fresh_run_state()
	restored.apply_saved_state(snapshot)
	expect(restored.week_actions_remaining == remaining, "remaining visits round-trip through save/load")
	expect(restored.weekly_recommended_plant_ids.has(stocked[0]), "already-pitched plants round-trip through save/load")

	# Migration: a pre-feature save (no action keys) restores to a full, usable week.
	var legacy := _fresh_run_state()
	legacy.apply_saved_state({"week": 3, "cash": 100, "reputation": 12})
	expect(legacy.week_action_allowance > 0, "a legacy save migrates to a full week allowance")
	expect(legacy.week_actions_remaining == legacy.week_action_allowance, "a legacy save opens with all visits available")

# --- scene-driven behavioral tests: drive the real overlay, assert observable state ---
# These exist so "focus is reachable and scroll follows it at 1280x800" and "the flow
# actually moves the run forward" are machine-verified, not left to a human launching the
# build (issue #98). Geometry (rects, viewport containment) is CPU-side layout and works
# under --headless; only pixels need a renderer, which is the screenshot pass's job.

const ONSCREEN_TOL := 2.0

# The stand renders 16 inventory buttons (~1660px) into an ~800px overlay. Focusing the
# last one must scroll it into the ScrollContainer's viewport — the exact scroll-follows-
# focus guarantee issue #94 shipped and issue #98 now proves by geometry. Without the
# ScrollContainer + follow_focus this button sits ~1500px down, far outside the panel.
func scene_test_scroll_follows_focus_into_view() -> void:
	var stand := await _mount_stand()
	var inventory_list: Control = stand.inventory_list
	var scroll: Control = inventory_list.get_parent() as Control
	expect(scroll is ScrollContainer, "the inventory list must live inside a ScrollContainer")
	var count := inventory_list.get_child_count()
	expect(count > 4, "the inventory must render enough buttons to overflow the panel")
	if count == 0 or not (scroll is ScrollContainer):
		stand.queue_free()
		return

	var last_button := inventory_list.get_child(count - 1) as Control
	last_button.grab_focus()
	await _settle()

	var focus_owner := stand.get_viewport().gui_get_focus_owner()
	expect(focus_owner == last_button, "the last inventory button can take focus")

	var b := last_button.get_global_rect()
	var s := scroll.get_global_rect()
	expect(b.position.y >= s.position.y - ONSCREEN_TOL,
		"scroll follows focus: the focused item's top is pulled into the viewport, not left above it")
	expect(b.end.y <= s.end.y + ONSCREEN_TOL,
		"scroll follows focus: the focused item's bottom is pulled into the viewport, not left below it")
	stand.queue_free()

# Walk the deliberate cross-section focus path (the shoulder-button jump) all the way
# around and assert every landing control is visible and fully inside the 1280x800
# viewport. This is the "no focusable element sits offscreen unreachable" guarantee, made
# machine-checkable across whatever panels the stand currently shows.
func scene_test_every_section_anchor_stays_on_screen() -> void:
	var stand := await _mount_stand()
	var viewport_rect := Rect2(Vector2.ZERO, Vector2(DECK_SIZE))
	# One extra step than there are sections guarantees we visit each and wrap back.
	for _i in range(8):
		stand._cycle_section_focus(1)
		await _settle(2)
		var owner: Control = stand.get_viewport().gui_get_focus_owner()
		expect(owner != null, "the shoulder-button jump always lands on a real control")
		if owner == null:
			continue
		expect(owner.is_visible_in_tree(), "the focused control is actually visible")
		var r := owner.get_global_rect()
		expect(viewport_rect.grow(ONSCREEN_TOL).encloses(r),
			"focused control '%s' stays fully on screen at 1280x800 (rect %s)" % [owner.name, r])
	stand.queue_free()

# The SafeArea holds every panel and label. Its full-rect anchors pin it to the viewport,
# but if the content's minimum width exceeds 1280 the MarginContainer grows past the
# window and its grow-both direction shoves the left edge off-screen (negative x) —
# clipping headings and body text while focusable controls stay reachable (issue #103,
# surfaced by #98's screenshots). scene_test_every_section_anchor_stays_on_screen only
# checks *focusable* controls, so it can't catch label bleed; this asserts the whole
# content rect stays inside 1280x800 across the modes and weeks where content changes most.
const STAND_MODES := ["all", "signal_board", "plant_stand", "propagation_bench", "ledger", "journal"]

func scene_test_stand_content_never_overflows_viewport() -> void:
	var stand := await _mount_stand()
	var rs = stand.run_state
	var viewport_rect := Rect2(Vector2.ZERO, Vector2(DECK_SIZE))
	for week in range(3):
		for mode in STAND_MODES:
			stand.open_station(mode)
			await _settle(2)
			var r: Rect2 = stand.get_node("SafeArea").get_global_rect()
			expect(viewport_rect.grow(ONSCREEN_TOL).encloses(r),
				"stand content stays inside 1280x800 in mode '%s' week %d — no text bleeds off-edge (rect %s)" % [mode, int(rs.week), r])
		# Advance the week with real work so later weeks' content (customer memory, ledger
		# history, calendar text) is exercised, since content width shifts week to week.
		stand.open_station("all")
		await _settle(1)
		var stocked := _in_stock_plant_ids(rs)
		if not stocked.is_empty():
			stand._recommend_plant(stocked[0])
			await _settle(1)
		stand._on_advance_week_button_pressed()
		await _settle(1)
	stand.queue_free()

# Driving the real UI handlers (not just the rules layer) must move the run forward:
# recommending an in-stock plant registers the visit, and closing the week advances it
# and refreshes the action budget. Catches a UI-layer regression that silently drops the
# handler wiring even while the core rules still pass.
func scene_test_recommend_and_advance_drive_run_state() -> void:
	var stand := await _mount_stand()
	var rs = stand.run_state
	var stocked := _in_stock_plant_ids(rs)
	expect(stocked.size() > 0, "there is an in-stock plant to recommend")
	if stocked.is_empty():
		stand.queue_free()
		return

	var plant_id: String = stocked[0]
	stand._recommend_plant(plant_id)
	await _settle(1)
	expect(rs.weekly_recommended_plant_ids.has(plant_id),
		"recommending through the stand registers the visit on the run state")

	var week_before: int = rs.week
	stand._on_advance_week_button_pressed()
	await _settle(1)
	expect(rs.week == week_before + 1, "closing the week through the stand advances the calendar")
	expect(rs.week_actions_remaining == rs.week_action_allowance,
		"closing the week refreshes the visit budget through the stand")
	stand.queue_free()
