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

var _failures: Array[String] = []
var _current := ""

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
