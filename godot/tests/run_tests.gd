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

var _failures: Array[String] = []
var _current := ""

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

func _initialize() -> void:
	var tests := []
	for method in get_method_list():
		var name: String = method.get("name", "")
		if name.begins_with("test_"):
			tests.append(name)
	tests.sort()
	for name in tests:
		_current = name
		call(name)
	if _failures.is_empty():
		print("ok - %d GDScript test(s) passed" % tests.size())
		quit(0)
	else:
		for failure in _failures:
			printerr("FAIL - %s" % failure)
		printerr("%d assertion(s) failed" % _failures.size())
		quit(1)

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
