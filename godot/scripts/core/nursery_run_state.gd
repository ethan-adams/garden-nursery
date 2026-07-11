class_name NurseryRunState
extends RefCounted

const NurseryRules := preload("res://scripts/core/nursery_rules.gd")

# Weekly action economy (issue #93). The week grants a small pool of "visits" — the
# meaningful things you can do at the stand before the week closes. Recommending,
# restocking, and starting a propagation tray each spend one, so infinite intra-week
# money loops (buy-restock / spam-recommend) close and the week becomes a real
# constraint. Reputation is consumed here: a better-regarded stand draws a busier week,
# so standing earned now buys more room to act next week. Kept gentle — scarcity should
# create decisions, not punishment.
const WEEK_ACTION_BASE := 4
const WEEK_ACTION_REPUTATION_STEP := 6
const WEEK_ACTION_MAX := 8

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
var customer_memory: Dictionary = {}
var event_contributions: Dictionary = {}
var resolved_events: Array[String] = []
var selected_discoveries: Dictionary = {}
var journal_week_reflections: Array[String] = []
var weekly_customer_notes: Array[String] = []
var weekly_recommendations: Array[String] = []
var weekly_cash_from_sales := 0
var weekly_reputation_delta := 0
var weekly_bench_spend := 0
var weekly_restock_spend := 0
var weekly_restocked_plants := 0
var weekly_plants_sold := 0
var weekly_recommended_plant_ids: Array[String] = []
var week_action_allowance := 0
var week_actions_remaining := 0
var log_lines: Array[String] = []


func setup(next_plants: Array, next_customers: Array, next_region: Dictionary, next_dialogue: Dictionary) -> void:
	plants = next_plants
	customers = next_customers
	region = next_region
	dialogue = next_dialogue
	relationship_notes = {}
	customer_memory = {}
	event_contributions = {}
	resolved_events = []
	selected_discoveries = fresh_discoveries()
	journal_week_reflections = []
	propagation_trays = []
	propagation_capacity = 3
	next_propagation_tray_id = 1
	var starting_state: Dictionary = region.get("starting_state", {})
	week = int(starting_state.get("week", week))
	cash = int(starting_state.get("cash", cash))
	reputation = int(starting_state.get("reputation", reputation))
	# After reputation is known, so the first week's visit allowance reflects it.
	reset_week_tracking()
	selected_signal_index = 0
	if not plants.is_empty():
		selected_plant_id = plants[0].get("id", "")
	for customer in customers:
		var customer_id: String = customer.get("id", "")
		relationship_notes[customer_id] = []
		customer_memory[customer_id] = fresh_customer_memory()
	log_lines = [
		"Opened the roadside stand beside the wet lane.",
		"Mara, Tovan, and Cilla all left clues before buying anything."
	]


func recommend_plant(plant_id: String) -> Dictionary:
	selected_plant_id = plant_id
	var plant := find_plant(plant_id)
	if plant.is_empty():
		return {}
	if weekly_recommended_plant_ids.has(plant_id):
		return {
			"outcome_text": "%s already had its turn with the regulars this week. A second pitch the same week won't land differently — try another plant, or close the ledger to reset the visits." % plant.get("name", "That plant"),
			"log": "Skipped re-pitching %s; already recommended this week." % plant.get("name", "a plant")
		}
	if not has_week_action():
		return {
			"outcome_text": no_visits_left_text("recommend another plant"),
			"log": "No visits left to recommend %s this week." % plant.get("name", "a plant")
		}
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
		update_customer_memory(customer, plant, outcome, fit)
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
	weekly_recommended_plant_ids.append(plant_id)
	spend_week_action()
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
	if not has_week_action():
		return {
			"outcome_text": no_visits_left_text("start a propagation tray")
		}
	var cost := int(profile.get("cost", 0))
	if cash < cost:
		return {
			"outcome_text": "The bench stayed empty. You need $%d to start %s." % [cost, plant.get("name", "that tray")]
		}
	var care_fit := NurseryRules.care_climate_fit(plant, region, current_signal())
	var climate_score := int(care_fit.get("score", 0))
	var adjusted_success: float = clamp(float(profile.get("success_chance", 0.75)) + (float(climate_score) * 0.03), 0.45, 0.98)
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
	spend_week_action()
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


func restock_selected_plant() -> Dictionary:
	var plant := find_plant(selected_plant_id)
	if plant.is_empty():
		return {}
	if not has_week_action():
		return {
			"outcome_text": no_visits_left_text("place a supplier order")
		}
	var quote := restock_quote(plant)
	if not bool(quote.get("can_order", false)):
		return {
			"outcome_text": quote.get("reason", "The supplier order did not go through.")
		}
	var cost := int(quote.get("cost", 0))
	var quantity := int(quote.get("quantity", 0))
	cash -= cost
	plant["starting_stock"] = int(plant.get("starting_stock", 0)) + quantity
	weekly_restock_spend += cost
	weekly_restocked_plants += quantity
	spend_week_action()
	return {
		"outcome_text": "Ordered %d %s for $%d wholesale. Shelf stock is now %d, with about $%d margin if demand holds." % [
			quantity,
			plant.get("name", "plant"),
			cost,
			int(plant.get("starting_stock", 0)),
			max(0, (int(plant.get("price", 0)) * quantity) - cost)
		],
		"log": "Restocked %s: +%d for $%d." % [plant.get("name", "plant"), quantity, cost]
	}


func active_community_event() -> Dictionary:
	for event in region.get("community_events", []):
		var event_id: String = event.get("id", "")
		if resolved_events.has(event_id):
			continue
		if week >= int(event.get("start_week", 1)) and week <= int(event.get("deadline_week", 1)):
			return event
	return {}


func can_contribute_selected_plant_to_event() -> bool:
	var event := active_community_event()
	if event.is_empty():
		return false
	var plant := find_plant(selected_plant_id)
	return not plant.is_empty() and int(plant.get("starting_stock", 0)) > 0


func contribute_selected_plant_to_event() -> Dictionary:
	var event := active_community_event()
	var plant := find_plant(selected_plant_id)
	if event.is_empty() or plant.is_empty():
		return {}
	if int(plant.get("starting_stock", 0)) <= 0:
		return {
			"outcome_text": "The seed-swap table needs real starts, not just a good tag."
		}
	var event_id: String = event.get("id", "")
	if not event_contributions.has(event_id):
		event_contributions[event_id] = {}
	var contributions: Dictionary = event_contributions[event_id]
	var plant_id: String = plant.get("id", "")
	plant["starting_stock"] = int(plant.get("starting_stock", 0)) - 1
	contributions[plant_id] = int(contributions.get(plant_id, 0)) + 1
	event_contributions[event_id] = contributions
	remember_discovery("plants", plant_id)
	var match_count := NurseryRules.trait_score(plant.get("traits", []), event.get("preferred_traits", []))
	return {
		"outcome_text": "Set aside 1 %s for %s. %s\nEtiquette: %s" % [
			plant.get("name", "plant"),
			event.get("name", "the event"),
			"Good local fit." if match_count > 0 else "Useful, though not what the table asked for first.",
			event.get("etiquette", "Label it honestly.")
		],
		"log": "Prepared %s for %s." % [plant.get("name", "plant"), event.get("name", "event")]
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
	var event_result := resolve_due_community_events(closing_week)
	var event_cash_bonus := int(event_result.get("cash", 0))
	var event_reputation_bonus := int(event_result.get("reputation", 0))
	cash += market_cash_bonus
	cash += event_cash_bonus
	reputation += market_reputation_bonus
	reputation += event_reputation_bonus
	var text := ledger_text(
		closing_week,
		cash_before_ledger,
		reputation_before_ledger,
		market_cash_bonus,
		market_reputation_bonus,
		outcome,
		propagation_text,
		event_result
	)
	remember_week_reflection(closing_week, outcome)
	week += 1
	reset_week_tracking()
	return {
		"outcome_text": text,
		"log": "Ledger closed week %d: %s" % [closing_week, outcome.get("id", "quiet_week")]
	}


func resolve_due_community_events(closing_week: int) -> Dictionary:
	var lines: Array[String] = []
	var cash_bonus := 0
	var reputation_bonus := 0
	for event in region.get("community_events", []):
		var event_id: String = event.get("id", "")
		if resolved_events.has(event_id) or closing_week < int(event.get("deadline_week", 1)):
			continue
		var contributions: Dictionary = event_contributions.get(event_id, {})
		var score := 0
		var count := 0
		for plant_id in contributions.keys():
			var plant := find_plant(plant_id)
			var amount := int(contributions.get(plant_id, 0))
			count += amount
			score += amount * max(1, NurseryRules.trait_score(plant.get("traits", []), event.get("preferred_traits", [])))
		if count <= 0:
			reputation_bonus -= 1
			lines.append("%s passed with an empty corner where your labels should have been." % event.get("name", "The event"))
		else:
			var earned_cash := int(event.get("cash_reward", 0))
			var earned_rep := int(event.get("reputation_reward", 0))
			if score < 3:
				earned_cash = int(round(float(earned_cash) * 0.5))
				earned_rep = max(1, earned_rep - 2)
			cash_bonus += earned_cash
			reputation_bonus += earned_rep
			lines.append("%s accepted %d contribution%s. Score %d; +$%d, %+d reputation." % [
				event.get("name", "Event"),
				count,
				plural_suffix(count),
				score,
				earned_cash,
				earned_rep
			])
			for customer in customers:
				remember_customer_note(customer.get("id", ""), event.get("relationship_note", "helped the seed swap"))
		resolved_events.append(event_id)
	if lines.is_empty():
		return {}
	return {
		"cash": cash_bonus,
		"reputation": reputation_bonus,
		"text": " ".join(lines)
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
	var weather_adjustment := propagation_weather_adjustment(plant)
	var success_chance: float = clamp(float(tray.get("success_chance", 0.75)) + weather_adjustment, 0.35, 0.98)
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
			"text": "%s tray %s: %d of %d starts joined inventory. %s" % [
				plant.get("name", "Propagation"),
				result_label,
				rooted_count,
				yield_count,
				weather_propagation_text(weather_adjustment)
			]
		}
	add_log("Propagation failed before saleable stock.")
	return {
		"rooted": 0,
		"text": "%s tray failed gently: green at the edges, but not saleable yet. %s" % [
			plant.get("name", "Propagation"),
			weather_propagation_text(weather_adjustment)
		]
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
		"customer_memory": customer_memory,
		"event_contributions": event_contributions,
		"resolved_events": resolved_events,
		"discoveries": selected_discoveries,
		"week_reflections": journal_week_reflections,
		"week_action_allowance": week_action_allowance,
		"week_actions_remaining": week_actions_remaining,
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
	customer_memory = sanitize_customer_memory(saved_state.get("customer_memory", {}))
	event_contributions = sanitize_dictionary(saved_state.get("event_contributions", {}))
	resolved_events = strings_from(saved_state.get("resolved_events", []))
	selected_discoveries = sanitize_discoveries(saved_state.get("discoveries", {}))
	journal_week_reflections = strings_from(saved_state.get("week_reflections", [])).slice(0, 6)
	apply_weekly_activity(saved_state.get("weekly_activity", {}))
	# Migration: saves from before the weekly action economy grant a fresh full week.
	week_action_allowance = maxi(1, int(saved_state.get("week_action_allowance", week_action_budget())))
	week_actions_remaining = clampi(int(saved_state.get("week_actions_remaining", week_action_allowance)), 0, week_action_allowance)
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
	weekly_restock_spend = 0
	weekly_restocked_plants = 0
	weekly_plants_sold = 0
	weekly_recommended_plant_ids = []
	week_action_allowance = week_action_budget()
	week_actions_remaining = week_action_allowance


# How many stand actions this week affords. Grows gently with reputation (a busier stand
# as word spreads), capped so it can never re-open an infinite loop.
func week_action_budget() -> int:
	var bonus := clampi(reputation / WEEK_ACTION_REPUTATION_STEP, 0, WEEK_ACTION_MAX - WEEK_ACTION_BASE)
	return WEEK_ACTION_BASE + bonus


func has_week_action() -> bool:
	return week_actions_remaining > 0


func spend_week_action() -> void:
	week_actions_remaining = maxi(0, week_actions_remaining - 1)


func no_visits_left_text(next_action: String) -> String:
	return "The week's visits are spent (%d of %d used). Close the ledger week to reopen the stand before you %s." % [
		week_action_allowance,
		week_action_allowance,
		next_action
	]


func current_signal() -> Dictionary:
	var signals: Array = region.get("market_signals", [])
	if signals.is_empty():
		return current_calendar_signal()
	return merged_signal_with_calendar(signals[selected_signal_index % signals.size()])


func current_calendar_entry() -> Dictionary:
	var calendar: Array = region.get("season_calendar", [])
	if calendar.is_empty():
		return {}
	var index := int(clamp(week - 1, 0, calendar.size() - 1))
	return calendar[index]


func current_calendar_signal() -> Dictionary:
	var entry := current_calendar_entry()
	if entry.is_empty():
		return {}
	return {
		"id": "calendar_week_%d" % week,
		"source": "%s forecast" % entry.get("weather", "weather"),
		"text": entry.get("forecast", ""),
		"points_to_traits": entry.get("points_to_traits", []),
		"risk_traits": entry.get("risk_traits", []),
		"uncertainty": float(entry.get("uncertainty", 0.25))
	}


func merged_signal_with_calendar(signal_data: Dictionary) -> Dictionary:
	var entry := current_calendar_entry()
	if entry.is_empty():
		return signal_data
	var merged := signal_data.duplicate(true)
	merged["source"] = "%s + %s" % [signal_data.get("source", "market signal"), entry.get("weather", "forecast")]
	merged["text"] = "%s\nForecast: %s" % [signal_data.get("text", ""), entry.get("forecast", "")]
	merged["points_to_traits"] = _unique_strings(signal_data.get("points_to_traits", []) + entry.get("points_to_traits", []))
	merged["risk_traits"] = _unique_strings(signal_data.get("risk_traits", []) + entry.get("risk_traits", []))
	merged["uncertainty"] = max(float(signal_data.get("uncertainty", 0.0)), float(entry.get("uncertainty", 0.0)))
	return merged


func propagation_weather_adjustment(plant: Dictionary) -> float:
	var entry := current_calendar_entry()
	if entry.is_empty():
		return 0.0
	var traits: Array = plant.get("traits", [])
	var bonus := NurseryRules.trait_score(traits, entry.get("propagation_bonus_traits", []))
	var risk := NurseryRules.trait_score(traits, entry.get("propagation_risk_traits", []))
	return clamp((float(bonus) * 0.04) - (float(risk) * 0.06), -0.18, 0.16)


func weather_propagation_text(adjustment: float) -> String:
	var entry := current_calendar_entry()
	if entry.is_empty():
		return ""
	if adjustment > 0.01:
		return "%s helped the tray." % entry.get("weather", "weather")
	if adjustment < -0.01:
		return "%s made the tray work harder." % entry.get("weather", "weather")
	return "%s kept conditions even." % entry.get("weather", "weather")


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


func restock_quote(plant: Dictionary) -> Dictionary:
	var stock := int(plant.get("starting_stock", 0))
	var limit := stock_limit_for(plant)
	var quantity: int = min(restock_quantity_for(plant), max(0, limit - stock))
	var cost := restock_cost_for(plant, quantity)
	if quantity <= 0:
		return {
			"can_order": false,
			"quantity": 0,
			"cost": 0,
			"reason": "%s is already at the shelf cap of %d. More would be overstock." % [plant.get("name", "This plant"), limit]
		}
	if cash < cost:
		return {
			"can_order": false,
			"quantity": quantity,
			"cost": cost,
			"reason": "The supplier wants $%d for %d %s. Cash on hand is $%d." % [cost, quantity, plant.get("name", "plants"), cash]
		}
	return {
		"can_order": true,
		"quantity": quantity,
		"cost": cost,
		"limit": limit
	}


func restock_cost_for(plant: Dictionary, quantity: int) -> int:
	var unit_cost := int(max(2, round(float(plant.get("price", 0)) * 0.55)))
	return unit_cost * quantity


func restock_quantity_for(plant: Dictionary) -> int:
	if plant.get("traits", []).has("quick-crop"):
		return 4
	return 3


func stock_limit_for(plant: Dictionary) -> int:
	if plant.get("traits", []).has("tender"):
		return 8
	if plant.get("traits", []).has("low-effort"):
		return 14
	return 12


func restock_margin_text(plant: Dictionary) -> String:
	var quantity := restock_quantity_for(plant)
	var cost := restock_cost_for(plant, quantity)
	var margin: int = max(0, (int(plant.get("price", 0)) * quantity) - cost)
	return "Restock %d/$%d margin $%d cap %d" % [quantity, cost, margin, stock_limit_for(plant)]


func plant_care_text(plant: Dictionary) -> String:
	var care_needs: Dictionary = plant.get("care_needs", {})
	var care_fit := NurseryRules.care_climate_fit(plant, region, current_signal())
	return "Care: %s water, %s light, %s. %s" % [
		care_needs.get("water", "steady"),
		care_needs.get("light", "mixed"),
		care_needs.get("difficulty", "moderate"),
		care_fit.get("summary", "")
	]


func calendar_summary_text() -> String:
	var entry := current_calendar_entry()
	if entry.is_empty():
		return "No forecast posted."
	return "%s, %s: %s (%d%% uncertain)." % [
		entry.get("season", region.get("season", "season")),
		entry.get("weather", "weather"),
		entry.get("forecast", ""),
		int(float(entry.get("uncertainty", 0.0)) * 100.0)
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


func _unique_strings(values: Array) -> Array[String]:
	var seen := {}
	var unique: Array[String] = []
	for value in values:
		var text := str(value)
		if text.is_empty() or seen.has(text):
			continue
		seen[text] = true
		unique.append(text)
	return unique


func weekly_activity_snapshot() -> Dictionary:
	return {
		"customer_notes": weekly_customer_notes,
		"recommendations": weekly_recommendations,
		"cash_from_sales": weekly_cash_from_sales,
		"reputation_delta": weekly_reputation_delta,
		"bench_spend": weekly_bench_spend,
		"restock_spend": weekly_restock_spend,
		"restocked_plants": weekly_restocked_plants,
		"plants_sold": weekly_plants_sold,
		"recommended_plant_ids": weekly_recommended_plant_ids
	}


func apply_weekly_activity(activity_data) -> void:
	if typeof(activity_data) != TYPE_DICTIONARY:
		return
	weekly_customer_notes = strings_from(activity_data.get("customer_notes", []))
	weekly_recommendations = strings_from(activity_data.get("recommendations", []))
	weekly_cash_from_sales = int(activity_data.get("cash_from_sales", 0))
	weekly_reputation_delta = int(activity_data.get("reputation_delta", 0))
	weekly_bench_spend = int(activity_data.get("bench_spend", 0))
	weekly_restock_spend = int(activity_data.get("restock_spend", 0))
	weekly_restocked_plants = int(activity_data.get("restocked_plants", 0))
	weekly_plants_sold = int(activity_data.get("plants_sold", 0))
	weekly_recommended_plant_ids = strings_from(activity_data.get("recommended_plant_ids", []))


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


func fresh_customer_memory() -> Dictionary:
	return {
		"visits": 0,
		"satisfaction": 0,
		"last_plant_id": "",
		"last_plant_name": "",
		"last_outcome": "new",
		"unresolved_need": ""
	}


func sanitize_customer_memory(value) -> Dictionary:
	var sanitized := {}
	for customer in customers:
		var customer_id: String = customer.get("id", "")
		var memory := fresh_customer_memory()
		if typeof(value) == TYPE_DICTIONARY and typeof(value.get(customer_id, {})) == TYPE_DICTIONARY:
			var saved_memory: Dictionary = value.get(customer_id, {})
			memory["visits"] = max(0, int(saved_memory.get("visits", 0)))
			memory["satisfaction"] = clamp(int(saved_memory.get("satisfaction", 0)), -5, 8)
			memory["last_plant_id"] = saved_memory.get("last_plant_id", "")
			memory["last_plant_name"] = saved_memory.get("last_plant_name", "")
			memory["last_outcome"] = saved_memory.get("last_outcome", "new")
			memory["unresolved_need"] = saved_memory.get("unresolved_need", "")
		sanitized[customer_id] = memory
	return sanitized


func update_customer_memory(customer: Dictionary, plant: Dictionary, outcome: Dictionary, fit: Dictionary) -> void:
	var customer_id: String = customer.get("id", "")
	if customer_id.is_empty():
		return
	if not customer_memory.has(customer_id):
		customer_memory[customer_id] = fresh_customer_memory()
	var memory: Dictionary = customer_memory[customer_id]
	memory["visits"] = int(memory.get("visits", 0)) + 1
	memory["last_plant_id"] = plant.get("id", "")
	memory["last_plant_name"] = plant.get("name", "that plant")
	var reputation_delta := int(outcome.get("reputation", 0))
	memory["satisfaction"] = clamp(int(memory.get("satisfaction", 0)) + reputation_delta, -5, 8)
	if bool(outcome.get("sold", false)) and reputation_delta >= 2:
		memory["last_outcome"] = "trusted"
		memory["unresolved_need"] = ""
	elif bool(outcome.get("sold", false)):
		memory["last_outcome"] = "careful"
		memory["unresolved_need"] = fit.get("care_summary", "watch the care tag")
	elif reputation_delta < 0:
		memory["last_outcome"] = "strained"
		memory["unresolved_need"] = "needs a better fit than %s" % plant.get("name", "that plant")
	else:
		memory["last_outcome"] = "curious"
		memory["unresolved_need"] = "still deciding after %s" % plant.get("name", "that plant")
	customer_memory[customer_id] = memory


func customer_memory_text(customer: Dictionary) -> String:
	var customer_id: String = customer.get("id", "")
	if not customer_memory.has(customer_id):
		return "First visit. Listen before selling."
	var memory: Dictionary = customer_memory[customer_id]
	var visits := int(memory.get("visits", 0))
	if visits <= 0:
		return "First visit. Listen before selling."
	var beat_key := "careful"
	var satisfaction := int(memory.get("satisfaction", 0))
	if satisfaction >= 3:
		beat_key = "trust_up"
	elif satisfaction < 0:
		beat_key = "trust_down"
	var beats: Dictionary = customer.get("returning_beats", {})
	var beat: String = beats.get(beat_key, "They remember last week's recommendation.")
	var unresolved: String = memory.get("unresolved_need", "")
	var plant_name: String = memory.get("last_plant_name", "")
	var text := "Memory %+d after %d visit%s. Last: %s. %s" % [
		satisfaction,
		visits,
		plural_suffix(visits),
		plant_name,
		beat
	]
	if not unresolved.is_empty():
		text = "%s Hook: %s." % [text, unresolved]
	return text


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


func ledger_text(closing_week: int, cash_before_ledger: int, reputation_before_ledger: int, market_cash_bonus: int, market_reputation_bonus: int, outcome: Dictionary, propagation_text: String, event_result: Dictionary = {}) -> String:
	var cash_delta := cash - cash_before_ledger
	var reputation_delta := reputation - reputation_before_ledger
	var propagation_summary := propagation_text
	if propagation_summary.is_empty():
		propagation_summary = propagation_ledger_status()
	var event_summary: String = event_result.get("text", active_event_status_text())
	var consequence: String = outcome.get("text", "The week ended quietly. The ledger learned less than you did.")
	return "Week %d Ledger\nCash: $%d now (%+d close, $%d sales, $%d market, $%d event, $%d bench spend, $%d restock).\nReputation: %d now (%+d close, %+d customer trust, %+d market, %+d event).\nInventory: %d saleable plants after %d sold and %d restocked.\nStock read: %s\nMarket learning: %s\nCustomer notes: %s\n%s\nPropagation: %s\nSeed Swap: %s\nHush Arbor: %s" % [
		closing_week,
		cash,
		cash_delta,
		weekly_cash_from_sales,
		market_cash_bonus,
		int(event_result.get("cash", 0)),
		weekly_bench_spend,
		weekly_restock_spend,
		reputation,
		reputation_delta,
		weekly_reputation_delta,
		market_reputation_bonus,
		int(event_result.get("reputation", 0)),
		inventory_total(),
		weekly_plants_sold,
		weekly_restocked_plants,
		inventory_economy_text(),
		market_learning_text(),
		relationship_summary(),
		recommendation_summary(),
		propagation_summary,
		event_summary,
		consequence
	]


func active_event_status_text() -> String:
	var event := active_community_event()
	if event.is_empty():
		return "No active community table."
	var contributions: Dictionary = event_contributions.get(event.get("id", ""), {})
	var count := 0
	for amount in contributions.values():
		count += int(amount)
	return "%s due week %d: %d contribution%s prepared. %s" % [
		event.get("name", "Event"),
		int(event.get("deadline_week", week)),
		count,
		plural_suffix(count),
		event.get("request", "")
	]


func inventory_economy_text() -> String:
	var shortages: Array[String] = []
	var overstock: Array[String] = []
	var signal_data := current_signal()
	for plant in plants:
		var stock := int(plant.get("starting_stock", 0))
		var demand := NurseryRules.trait_score(plant.get("traits", []), signal_data.get("points_to_traits", []))
		if stock <= 1 and demand > 0:
			shortages.append(plant.get("name", "plant"))
		if stock >= stock_limit_for(plant):
			overstock.append(plant.get("name", "plant"))
	var parts: Array[String] = []
	if shortages.is_empty():
		parts.append("no urgent signal shortages")
	else:
		parts.append("short on %s" % ", ".join(shortages.slice(0, 3)))
	if overstock.is_empty():
		parts.append("no benches over cap")
	else:
		parts.append("overstock risk on %s" % ", ".join(overstock.slice(0, 3)))
	return "; ".join(parts)


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
	return "%s (%d%% uncertain). Weather: %s" % [
		text,
		int(float(signal_data.get("uncertainty", 0.0)) * 100.0),
		calendar_summary_text()
	]


func relationship_summary() -> String:
	if weekly_customer_notes.is_empty():
		return "No new regular notes. %s" % customer_trust_summary()
	var clipped := weekly_customer_notes.slice(0, min(2, weekly_customer_notes.size()))
	return "%s | %s" % [" | ".join(clipped), customer_trust_summary()]


func customer_trust_summary() -> String:
	var lines: Array[String] = []
	for customer in customers:
		var customer_id: String = customer.get("id", "")
		var memory: Dictionary = customer_memory.get(customer_id, fresh_customer_memory())
		lines.append("%s %+d" % [customer.get("display_name", "Customer"), int(memory.get("satisfaction", 0))])
	return "Trust: %s." % ", ".join(lines)


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
