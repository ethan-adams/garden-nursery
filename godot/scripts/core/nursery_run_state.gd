class_name NurseryRunState
extends RefCounted

const NurseryRules := preload("res://scripts/core/nursery_rules.gd")

var plants: Array = []
var customers: Array = []
var region: Dictionary = {}
var dialogue: Dictionary = {}
var week := 1
var cash := 120
var reputation := 12
var selected_signal_index := 0
var selected_plant_id := ""
var propagation_trays: Array = []
var propagation_capacity := 3
var next_propagation_tray_id := 1
var relationship_notes: Dictionary = {}
var selected_discoveries: Dictionary = {}
var journal_week_reflections: Array[String] = []
var weekly_customer_notes: Array[String] = []
var weekly_recommendations: Array[String] = []
var weekly_cash_from_sales := 0
var weekly_reputation_delta := 0
var weekly_bench_spend := 0
var weekly_plants_sold := 0
var log_lines: Array[String] = []


func setup(next_plants: Array, next_customers: Array, next_region: Dictionary, next_dialogue: Dictionary) -> void:
	plants = next_plants
	customers = next_customers
	region = next_region
	dialogue = next_dialogue
	relationship_notes = {}
	selected_discoveries = fresh_discoveries()
	journal_week_reflections = []
	propagation_trays = []
	propagation_capacity = 3
	next_propagation_tray_id = 1
	reset_week_tracking()
	var starting_state: Dictionary = region.get("starting_state", {})
	week = int(starting_state.get("week", week))
	cash = int(starting_state.get("cash", cash))
	reputation = int(starting_state.get("reputation", reputation))
	selected_signal_index = 0
	if not plants.is_empty():
		selected_plant_id = plants[0].get("id", "")
	for customer in customers:
		relationship_notes[customer.get("id", "")] = []
	log_lines = [
		"Opened the roadside stand beside the wet lane.",
		"Mara, Tovan, and Cilla all left clues before buying anything."
	]


func recommend_plant(plant_id: String) -> Dictionary:
	selected_plant_id = plant_id
	var plant := find_plant(plant_id)
	if plant.is_empty():
		return {}
	var signal_data := current_signal()
	remember_discovery("plants", plant.get("id", ""))
	remember_discovery("signals", signal_data.get("id", ""))
	var stock_available := int(plant.get("starting_stock", 0))
	if stock_available <= 0:
		var empty_line := "%s has an empty bench tag. The regulars noticed the idea, but no sale happened." % plant.get("name", "That plant")
		return {
			"outcome_text": empty_line,
			"log": "Recommended an empty %s bench; no one could buy it." % plant.get("name", "plant")
		}

	var lines: Array[String] = []
	var sold_count := 0
	var sale_total := 0
	var reputation_total := 0
	for customer in customers:
		remember_discovery("customers", customer.get("id", ""))
		var fit := NurseryRules.score_customer_fit(plant, customer, signal_data, region)
		var outcome := NurseryRules.customer_recommendation_outcome(plant, customer, fit, stock_available - sold_count)
		lines.append(outcome.get("line", ""))
		var customer_note: String = outcome.get("note", "")
		if not customer_note.is_empty():
			remember_customer_note(customer.get("id", ""), customer_note)
			weekly_customer_notes.append("%s: %s" % [customer.get("display_name", "Customer"), customer_note])
		if bool(outcome.get("sold", false)):
			sold_count += 1
			sale_total += int(outcome.get("cash", 0))
		reputation_total += int(outcome.get("reputation", 0))

	plant["starting_stock"] = int(max(0, stock_available - sold_count))
	cash += sale_total
	reputation += reputation_total
	weekly_cash_from_sales += sale_total
	weekly_reputation_delta += reputation_total
	weekly_plants_sold += sold_count
	weekly_recommendations.append("%s: %d sale%s, $%d, %+d reputation" % [
		plant.get("name", "Plant"),
		sold_count,
		plural_suffix(sold_count),
		sale_total,
		reputation_total
	])
	return {
		"outcome_text": recommendation_text(plant, signal_data, lines, sold_count, sale_total, reputation_total),
		"log": "Recommended %s to the regulars: %d sale%s, %+d reputation." % [
			plant.get("name", "a plant"),
			sold_count,
			plural_suffix(sold_count),
			reputation_total
		]
	}


func next_signal() -> bool:
	var signals: Array = region.get("market_signals", [])
	if signals.is_empty():
		return false
	selected_signal_index = (selected_signal_index + 1) % signals.size()
	remember_discovery("signals", current_signal().get("id", ""))
	return true


func start_propagation() -> Dictionary:
	if active_propagation_count() >= propagation_capacity:
		return {
			"outcome_text": "Every bench slot is full. Close a week to move the trays along before starting another."
		}
	var plant := find_plant(selected_plant_id)
	var profile := propagation_profile(plant)
	if plant.is_empty() or profile.is_empty():
		return {}
	var cost := int(profile.get("cost", 0))
	if cash < cost:
		return {
			"outcome_text": "The bench stayed empty. You need $%d to start %s." % [cost, plant.get("name", "that tray")]
		}
	var care_fit := NurseryRules.care_climate_fit(plant, region, current_signal())
	var climate_score := int(care_fit.get("score", 0))
	var adjusted_success = clamp(float(profile.get("success_chance", 0.75)) + (float(climate_score) * 0.03), 0.45, 0.98)
	cash -= cost
	weekly_bench_spend += cost
	var tray := {
		"id": next_propagation_tray_id,
		"plant_id": plant.get("id", ""),
		"method": profile.get("method", "propagation"),
		"weeks_remaining": int(profile.get("weeks", 1)),
		"yield": int(profile.get("yield", 1)),
		"success_chance": adjusted_success,
		"care_summary": care_fit.get("summary", "")
	}
	next_propagation_tray_id += 1
	propagation_trays.append(tray)
	return {
		"outcome_text": "You set a %s tray in slot %d of %d. It will need %d week%s before it can join inventory.\n%s" % [
			plant.get("name", "plant"),
			active_propagation_count(),
			propagation_capacity,
			int(tray.get("weeks_remaining", 1)),
			plural_suffix(int(tray.get("weeks_remaining", 1))),
			care_fit.get("summary", "")
		],
		"log": "Started %s by %s for $%d." % [plant.get("name", "a plant"), tray.get("method", "propagation"), cost]
	}


func advance_week() -> Dictionary:
	var closing_week := week
	var cash_before_ledger := cash
	var reputation_before_ledger := reputation
	var plant := find_plant(selected_plant_id)
	var outcome := NurseryRules.best_outcome_for(plant, region.get("week_outcomes", []))
	var propagation_text := process_propagation_week()
	var market_cash_bonus := int(outcome.get("cash_bonus", 0))
	var market_reputation_bonus := int(outcome.get("reputation_bonus", 0))
	cash += market_cash_bonus
	reputation += market_reputation_bonus
	var text := ledger_text(
		closing_week,
		cash_before_ledger,
		reputation_before_ledger,
		market_cash_bonus,
		market_reputation_bonus,
		outcome,
		propagation_text
	)
	remember_week_reflection(closing_week, outcome)
	week += 1
	reset_week_tracking()
	return {
		"outcome_text": text,
		"log": "Ledger closed week %d: %s" % [closing_week, outcome.get("id", "quiet_week")]
	}


func process_propagation_week() -> String:
	if propagation_trays.is_empty():
		return ""
	var remaining_trays: Array = []
	var lines: Array[String] = []
	for tray in propagation_trays:
		if typeof(tray) != TYPE_DICTIONARY:
			continue
		tray["weeks_remaining"] = int(tray.get("weeks_remaining", 0)) - 1
		var plant := find_plant(tray.get("plant_id", ""))
		if int(tray.get("weeks_remaining", 0)) > 0:
			remaining_trays.append(tray)
			lines.append("%s tray held steady: %d week%s left." % [
				plant.get("name", "Propagation"),
				int(tray.get("weeks_remaining", 0)),
				plural_suffix(int(tray.get("weeks_remaining", 0)))
			])
			continue
		var result := complete_propagation_tray(tray, plant)
		lines.append(result.get("text", "A tray finished quietly."))
	propagation_trays = remaining_trays
	return " ".join(lines)


func complete_propagation_tray(tray: Dictionary, plant: Dictionary) -> Dictionary:
	var yield_count := int(tray.get("yield", 1))
	var success_chance := float(tray.get("success_chance", 0.75))
	var roll := randf()
	var rooted_count := 0
	var result_label := "failed"
	if roll <= success_chance:
		rooted_count = yield_count
		result_label = "rooted cleanly"
	elif roll <= min(0.98, success_chance + 0.25):
		rooted_count = max(1, int(ceil(float(yield_count) * 0.45)))
		result_label = "partly rooted"
	if rooted_count > 0:
		plant["starting_stock"] = int(plant.get("starting_stock", 0)) + rooted_count
		add_log("Propagation finished: %s added %d stock." % [plant.get("name", "tray"), rooted_count])
		return {
			"rooted": rooted_count,
			"text": "%s tray %s: %d of %d starts joined inventory." % [
				plant.get("name", "Propagation"),
				result_label,
				rooted_count,
				yield_count
			]
		}
	add_log("Propagation failed before saleable stock.")
	return {
		"rooted": 0,
		"text": "%s tray failed gently: green at the edges, but not saleable yet." % plant.get("name", "Propagation")
	}


func save_state_snapshot() -> Dictionary:
	return {
		"week": week,
		"cash": cash,
		"reputation": reputation,
		"selected_signal_index": selected_signal_index,
		"selected_plant_id": selected_plant_id,
		"inventory_stock": inventory_stock_snapshot(),
		"propagation_trays": propagation_trays,
		"propagation_capacity": propagation_capacity,
		"next_propagation_tray_id": next_propagation_tray_id,
		"propagation_tray": legacy_propagation_tray_snapshot(),
		"customer_notes": relationship_notes,
		"discoveries": selected_discoveries,
		"week_reflections": journal_week_reflections,
		"weekly_activity": weekly_activity_snapshot()
	}


func apply_saved_state(saved_state: Dictionary) -> bool:
	if saved_state.is_empty():
		return false
	week = max(1, int(saved_state.get("week", week)))
	cash = int(saved_state.get("cash", cash))
	reputation = int(saved_state.get("reputation", reputation))
	selected_signal_index = max(0, int(saved_state.get("selected_signal_index", selected_signal_index)))
	selected_plant_id = saved_state.get("selected_plant_id", selected_plant_id)
	apply_inventory_stock(saved_state.get("inventory_stock", {}))
	propagation_capacity = max(1, int(saved_state.get("propagation_capacity", propagation_capacity)))
	propagation_trays = sanitize_propagation_trays(saved_state)
	next_propagation_tray_id = max(next_propagation_tray_id, int(saved_state.get("next_propagation_tray_id", next_propagation_tray_id)))
	relationship_notes = sanitize_relationship_notes(saved_state.get("customer_notes", {}))
	selected_discoveries = sanitize_discoveries(saved_state.get("discoveries", {}))
	journal_week_reflections = strings_from(saved_state.get("week_reflections", [])).slice(0, 6)
	apply_weekly_activity(saved_state.get("weekly_activity", {}))
	if find_plant(selected_plant_id).is_empty() and not plants.is_empty():
		selected_plant_id = plants[0].get("id", "")
	_repair_next_propagation_tray_id()
	return true


func reset_week_tracking() -> void:
	weekly_customer_notes = []
	weekly_recommendations = []
	weekly_cash_from_sales = 0
	weekly_reputation_delta = 0
	weekly_bench_spend = 0
	weekly_plants_sold = 0


func current_signal() -> Dictionary:
	var signals: Array = region.get("market_signals", [])
	if signals.is_empty():
		return {}
	return signals[selected_signal_index % signals.size()]


func find_plant(plant_id: String) -> Dictionary:
	for plant in plants:
		if plant.get("id", "") == plant_id:
			return plant
	return {}


func find_customer(customer_id: String) -> Dictionary:
	for customer in customers:
		if customer.get("id", "") == customer_id:
			return customer
	return {}


func find_signal(signal_id: String) -> Dictionary:
	for signal_data in region.get("market_signals", []):
		if signal_data.get("id", "") == signal_id:
			return signal_data
	return {}


func propagation_profile(plant: Dictionary) -> Dictionary:
	return plant.get("propagation", {})


func plant_care_text(plant: Dictionary) -> String:
	var care_needs: Dictionary = plant.get("care_needs", {})
	var care_fit := NurseryRules.care_climate_fit(plant, region, current_signal())
	return "Care: %s water, %s light, %s. %s" % [
		care_needs.get("water", "steady"),
		care_needs.get("light", "mixed"),
		care_needs.get("difficulty", "moderate"),
		care_fit.get("summary", "")
	]


func inventory_total() -> int:
	var total := 0
	for plant in plants:
		total += int(plant.get("starting_stock", 0))
	return total


func inventory_stock_snapshot() -> Dictionary:
	var snapshot := {}
	for plant in plants:
		snapshot[plant.get("id", "")] = int(plant.get("starting_stock", 0))
	return snapshot


func apply_inventory_stock(stock_data) -> void:
	if typeof(stock_data) != TYPE_DICTIONARY:
		return
	for plant in plants:
		var plant_id: String = plant.get("id", "")
		if stock_data.has(plant_id):
			plant["starting_stock"] = max(0, int(stock_data.get(plant_id, plant.get("starting_stock", 0))))


func active_propagation_count() -> int:
	return propagation_trays.size()


func has_open_propagation_slot() -> bool:
	return active_propagation_count() < propagation_capacity


func propagation_slots_label() -> String:
	return "%d/%d tray slots full" % [active_propagation_count(), propagation_capacity]


func propagation_status_lines() -> Array[String]:
	var lines: Array[String] = []
	for index in range(propagation_trays.size()):
		var tray: Dictionary = propagation_trays[index]
		var plant := find_plant(tray.get("plant_id", ""))
		lines.append("Slot %d: %s by %s, %d week%s left, yield %d, %d%% success." % [
			index + 1,
			plant.get("name", "Propagation"),
			tray.get("method", "propagation"),
			int(tray.get("weeks_remaining", 0)),
			plural_suffix(int(tray.get("weeks_remaining", 0))),
			int(tray.get("yield", 1)),
			int(round(float(tray.get("success_chance", 0.0)) * 100.0))
		])
	return lines


func legacy_propagation_tray_snapshot() -> Dictionary:
	if propagation_trays.is_empty():
		return {}
	return propagation_trays[0]


func sanitize_propagation_trays(saved_state: Dictionary) -> Array:
	var source = saved_state.get("propagation_trays", [])
	if typeof(source) != TYPE_ARRAY:
		var legacy_tray := sanitize_dictionary(saved_state.get("propagation_tray", {}))
		if legacy_tray.is_empty():
			return []
		source = [legacy_tray]
	var trays: Array = []
	for raw_tray in source:
		if typeof(raw_tray) != TYPE_DICTIONARY:
			continue
		var plant_id: String = raw_tray.get("plant_id", "")
		if plant_id.is_empty() or find_plant(plant_id).is_empty():
			continue
		var tray := {
			"id": max(1, int(raw_tray.get("id", next_propagation_tray_id))),
			"plant_id": plant_id,
			"method": raw_tray.get("method", "propagation"),
			"weeks_remaining": max(1, int(raw_tray.get("weeks_remaining", 1))),
			"yield": max(1, int(raw_tray.get("yield", 1))),
			"success_chance": clamp(float(raw_tray.get("success_chance", 0.75)), 0.0, 1.0),
			"care_summary": raw_tray.get("care_summary", "")
		}
		trays.append(tray)
		if trays.size() >= propagation_capacity:
			break
	return trays


func _repair_next_propagation_tray_id() -> void:
	for tray in propagation_trays:
		if typeof(tray) == TYPE_DICTIONARY:
			next_propagation_tray_id = max(next_propagation_tray_id, int(tray.get("id", 0)) + 1)


func weekly_activity_snapshot() -> Dictionary:
	return {
		"customer_notes": weekly_customer_notes,
		"recommendations": weekly_recommendations,
		"cash_from_sales": weekly_cash_from_sales,
		"reputation_delta": weekly_reputation_delta,
		"bench_spend": weekly_bench_spend,
		"plants_sold": weekly_plants_sold
	}


func apply_weekly_activity(activity_data) -> void:
	if typeof(activity_data) != TYPE_DICTIONARY:
		return
	weekly_customer_notes = strings_from(activity_data.get("customer_notes", []))
	weekly_recommendations = strings_from(activity_data.get("recommendations", []))
	weekly_cash_from_sales = int(activity_data.get("cash_from_sales", 0))
	weekly_reputation_delta = int(activity_data.get("reputation_delta", 0))
	weekly_bench_spend = int(activity_data.get("bench_spend", 0))
	weekly_plants_sold = int(activity_data.get("plants_sold", 0))


func sanitize_dictionary(value) -> Dictionary:
	if typeof(value) == TYPE_DICTIONARY:
		return value
	return {}


func sanitize_relationship_notes(value) -> Dictionary:
	var sanitized := {}
	for customer in customers:
		var customer_id: String = customer.get("id", "")
		sanitized[customer_id] = []
	if typeof(value) != TYPE_DICTIONARY:
		return sanitized
	for customer_id in value.keys():
		sanitized[customer_id] = strings_from(value.get(customer_id, [])).slice(0, 3)
	return sanitized


func sanitize_discoveries(value) -> Dictionary:
	var sanitized := fresh_discoveries()
	if typeof(value) != TYPE_DICTIONARY:
		return sanitized
	for kind in sanitized.keys():
		sanitized[kind] = strings_from(value.get(kind, []))
	return sanitized


func fresh_discoveries() -> Dictionary:
	return {
		"plants": [],
		"customers": [],
		"signals": []
	}


func strings_from(value) -> Array[String]:
	var strings: Array[String] = []
	if typeof(value) != TYPE_ARRAY:
		return strings
	for item in value:
		strings.append(str(item))
	return strings


func remember_discovery(kind: String, id: String) -> void:
	if id.is_empty():
		return
	if not selected_discoveries.has(kind):
		selected_discoveries[kind] = []
	var known: Array = selected_discoveries[kind]
	if not known.has(id):
		known.append(id)
	selected_discoveries[kind] = known


func known_discoveries(kind: String) -> Array:
	if not selected_discoveries.has(kind):
		return []
	return selected_discoveries[kind]


func remember_week_reflection(closing_week: int, outcome: Dictionary) -> void:
	var text := "Week %d: %s" % [
		closing_week,
		clip_text(outcome.get("text", "The week closed quietly."), 112)
	]
	journal_week_reflections.push_front(text)
	journal_week_reflections = journal_week_reflections.slice(0, 6)


func remember_customer_note(customer_id: String, note: String) -> void:
	if not relationship_notes.has(customer_id):
		relationship_notes[customer_id] = []
	var notes: Array = relationship_notes[customer_id]
	notes.push_front(note)
	relationship_notes[customer_id] = notes.slice(0, 3)


func latest_relationship_note(customer_id: String) -> String:
	if not relationship_notes.has(customer_id):
		return ""
	var notes: Array = relationship_notes[customer_id]
	if notes.is_empty():
		return ""
	return notes[0]


func add_log(message: String) -> void:
	log_lines.push_front(message)
	log_lines = log_lines.slice(0, 5)


func recommendation_text(plant: Dictionary, signal_data: Dictionary, lines: Array[String], sold_count: int, sale_total: int, reputation_total: int) -> String:
	return "%s against %s: %d sold, $%d, %+d reputation.\n%s" % [
		plant.get("name", "The plant"),
		signal_data.get("source", "the market signal"),
		sold_count,
		sale_total,
		reputation_total,
		"\n".join(lines)
	]


func ledger_text(closing_week: int, cash_before_ledger: int, reputation_before_ledger: int, market_cash_bonus: int, market_reputation_bonus: int, outcome: Dictionary, propagation_text: String) -> String:
	var cash_delta := cash - cash_before_ledger
	var reputation_delta := reputation - reputation_before_ledger
	var propagation_summary := propagation_text
	if propagation_summary.is_empty():
		propagation_summary = propagation_ledger_status()
	var consequence: String = outcome.get("text", "The week ended quietly. The ledger learned less than you did.")
	return "Week %d Ledger\nCash: $%d now (%+d close, $%d sales, $%d market, $%d bench spend).\nReputation: %d now (%+d close, %+d customer trust, %+d market).\nInventory: %d saleable plants after %d sold.\nMarket learning: %s\nCustomer notes: %s\n%s\nPropagation: %s\nHush Arbor: %s" % [
		closing_week,
		cash,
		cash_delta,
		weekly_cash_from_sales,
		market_cash_bonus,
		weekly_bench_spend,
		reputation,
		reputation_delta,
		weekly_reputation_delta,
		market_reputation_bonus,
		inventory_total(),
		weekly_plants_sold,
		market_learning_text(),
		relationship_summary(),
		recommendation_summary(),
		propagation_summary,
		consequence
	]


func market_learning_text() -> String:
	var signal_data := current_signal()
	var points_to: Array = signal_data.get("points_to_traits", [])
	var risks: Array = signal_data.get("risk_traits", [])
	var text := "%s pointed toward %s" % [
		signal_data.get("source", "The signal"),
		", ".join(points_to)
	]
	if not risks.is_empty():
		text = "%s and warned against %s" % [text, ", ".join(risks)]
	return "%s (%d%% uncertain)." % [text, int(float(signal_data.get("uncertainty", 0.0)) * 100.0)]


func relationship_summary() -> String:
	if weekly_customer_notes.is_empty():
		return "No new regular notes."
	var clipped := weekly_customer_notes.slice(0, min(2, weekly_customer_notes.size()))
	return " | ".join(clipped)


func recommendation_summary() -> String:
	if weekly_recommendations.is_empty():
		return "Recommendations: none recorded."
	return "Recommendations: %s." % " | ".join(weekly_recommendations.slice(0, min(2, weekly_recommendations.size())))


func propagation_ledger_status() -> String:
	if propagation_trays.is_empty():
		return "bench idle."
	return "%s: %s" % [propagation_slots_label(), " | ".join(propagation_status_lines().slice(0, 3))]


func clip_text(text: String, max_length: int) -> String:
	if text.length() <= max_length:
		return text
	return "%s..." % text.substr(0, max(0, max_length - 3))


func plural_suffix(amount: int) -> String:
	if amount == 1:
		return ""
	return "s"
