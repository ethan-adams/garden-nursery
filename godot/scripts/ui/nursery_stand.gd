extends Control

signal closed

const PLANTS_PATH := "res://data/plants/starter_plants.json"
const CUSTOMERS_PATH := "res://data/customers/hush_arbor_archetypes.json"
const REGION_PATH := "res://data/regions/hush_arbor.json"
const DIALOGUE_PATH := "res://data/dialogue/writing_sample_pack.json"

var plants: Array = []
var customers: Array = []
var region: Dictionary = {}
var dialogue: Dictionary = {}
var week := 1
var cash := 120
var reputation := 12
var selected_signal_index := 0
var selected_plant_id := ""
var propagation_tray: Dictionary = {}
var relationship_notes: Dictionary = {}
var weekly_customer_notes: Array[String] = []
var weekly_recommendations: Array[String] = []
var weekly_cash_from_sales := 0
var weekly_reputation_delta := 0
var weekly_bench_spend := 0
var weekly_plants_sold := 0
var log_lines: Array[String] = []
var station_mode := "all"

@onready var week_label: Label = %WeekValue
@onready var cash_label: Label = %CashValue
@onready var reputation_label: Label = %ReputationValue
@onready var title_label: Label = %Title
@onready var region_label: Label = %RegionLabel
@onready var signal_source_label: Label = %SignalSource
@onready var signal_text_label: Label = %SignalText
@onready var signal_traits_label: Label = %SignalTraits
@onready var inventory_list: VBoxContainer = %InventoryList
@onready var customer_list: VBoxContainer = %CustomerList
@onready var outcome_label: Label = %OutcomeText
@onready var propagation_status_label: Label = %PropagationStatus
@onready var start_propagation_button: Button = %StartPropagationButton
@onready var log_label: Label = %LogText
@onready var next_signal_button: Button = %NextSignalButton
@onready var advance_week_button: Button = %AdvanceWeekButton
@onready var close_button: Button = %CloseButton
@onready var signal_panel: PanelContainer = %SignalPanel
@onready var inventory_panel: PanelContainer = %InventoryPanel
@onready var customer_panel: PanelContainer = %CustomerPanel
@onready var outcome_panel: PanelContainer = %OutcomePanel
@onready var board_row: HBoxContainer = %BoardRow
@onready var lower_row: HBoxContainer = %LowerRow
@onready var propagation_heading: Label = %PropagationHeading
@onready var outcome_heading: Label = %OutcomeHeading

func _ready() -> void:
	_load_data()
	_setup_focus()
	_refresh_all()
	_apply_station_mode()


func open_station(next_station_mode: String, station_name: String = "") -> void:
	station_mode = next_station_mode
	if station_name.is_empty():
		station_name = _station_title(station_mode)
	region_label.text = "Hush Arbor roadside yard"
	title_label.text = station_name
	visible = true
	_apply_station_mode()
	_refresh_all()
	_grab_station_focus()


func close_station() -> void:
	visible = false
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		close_station()
		get_viewport().set_input_as_handled()


func _load_data() -> void:
	region = _read_json(REGION_PATH)
	dialogue = _read_json(DIALOGUE_PATH)
	plants = _read_json(PLANTS_PATH).get("plants", [])
	customers = _read_json(CUSTOMERS_PATH).get("customers", [])
	var starting_state: Dictionary = region.get("starting_state", {})
	week = int(starting_state.get("week", week))
	cash = int(starting_state.get("cash", cash))
	reputation = int(starting_state.get("reputation", reputation))
	if not plants.is_empty():
		selected_plant_id = plants[0].get("id", "")
	for customer in customers:
		relationship_notes[customer.get("id", "")] = []
	log_lines = [
		"Opened the roadside stand beside the wet lane.",
		"Mara, Tovan, and Cilla all left clues before buying anything."
	]


func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Missing data file: %s" % path)
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Invalid JSON catalog: %s" % path)
		return {}
	return parsed


func _setup_focus() -> void:
	next_signal_button.grab_focus()
	next_signal_button.focus_mode = Control.FOCUS_ALL
	start_propagation_button.focus_mode = Control.FOCUS_ALL
	advance_week_button.focus_mode = Control.FOCUS_ALL
	close_button.focus_mode = Control.FOCUS_ALL


func _refresh_all() -> void:
	week_label.text = str(week)
	cash_label.text = "$%d" % cash
	reputation_label.text = str(reputation)
	_render_signal()
	_render_inventory()
	_render_customers()
	_render_propagation_bench()
	_render_log()
	_apply_station_mode()


func _apply_station_mode() -> void:
	var is_signal := station_mode == "signal_board" or station_mode == "all"
	var is_stand := station_mode == "plant_stand" or station_mode == "all"
	var is_bench := station_mode == "propagation_bench" or station_mode == "all"
	var is_ledger := station_mode == "ledger" or station_mode == "all"

	signal_panel.visible = is_signal
	inventory_panel.visible = is_stand or is_bench
	customer_panel.visible = is_stand
	outcome_panel.visible = is_bench or is_ledger or station_mode == "all"
	board_row.visible = signal_panel.visible or inventory_panel.visible
	lower_row.visible = customer_panel.visible or outcome_panel.visible

	next_signal_button.visible = is_signal
	start_propagation_button.visible = is_bench or station_mode == "all"
	propagation_heading.visible = is_bench or station_mode == "all"
	propagation_status_label.visible = is_bench or station_mode == "all"
	advance_week_button.visible = is_ledger or station_mode == "all"
	outcome_heading.text = "Ledger"
	if is_bench and not is_ledger:
		outcome_heading.text = "Propagation Bench"
	elif station_mode == "all":
		outcome_heading.text = "Week Outcome"


func _grab_station_focus() -> void:
	match station_mode:
		"signal_board":
			next_signal_button.grab_focus()
		"plant_stand":
			_grab_first_inventory_focus()
		"propagation_bench":
			if not start_propagation_button.disabled:
				start_propagation_button.grab_focus()
			else:
				_grab_first_inventory_focus()
		"ledger":
			advance_week_button.grab_focus()
		_:
			next_signal_button.grab_focus()


func _grab_first_inventory_focus() -> void:
	for child in inventory_list.get_children():
		if child is Button:
			child.grab_focus()
			return
	close_button.grab_focus()


func _station_title(id: String) -> String:
	match id:
		"signal_board":
			return "Signal Board"
		"plant_stand":
			return "Plant Stand"
		"propagation_bench":
			return "Propagation Bench"
		"ledger":
			return "Ledger"
		_:
			return "Foothill Plant House"


func _render_signal() -> void:
	var signals: Array = region.get("market_signals", [])
	if signals.is_empty():
		return
	var signal_data: Dictionary = signals[selected_signal_index % signals.size()]
	signal_source_label.text = signal_data.get("source", "market signal").capitalize()
	signal_text_label.text = signal_data.get("text", "")
	signal_traits_label.text = "Points toward: %s\nRisk: %s\nUncertainty: %d%%" % [
		", ".join(signal_data.get("points_to_traits", [])),
		", ".join(signal_data.get("risk_traits", [])),
		int(float(signal_data.get("uncertainty", 0.0)) * 100.0)
	]


func _render_inventory() -> void:
	for child in inventory_list.get_children():
		child.queue_free()
	for plant in plants:
		var button := Button.new()
		button.text = "%s  $%d  Stock %d\n%s" % [
			plant.get("name", "Unnamed plant"),
			int(plant.get("price", 0)),
			int(plant.get("starting_stock", 0)),
			", ".join(plant.get("traits", []))
		]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size = Vector2(0, 76)
		button.focus_mode = Control.FOCUS_ALL
		button.pressed.connect(_recommend_plant.bind(plant.get("id", "")))
		inventory_list.add_child(button)


func _render_propagation_bench() -> void:
	if propagation_tray.is_empty():
		var plant := _find_plant(selected_plant_id)
		var profile := _propagation_profile(plant)
		if plant.is_empty() or profile.is_empty():
			propagation_status_label.text = "Bench idle. Choose a plant to see propagation options."
			start_propagation_button.disabled = true
			return
		propagation_status_label.text = "Bench idle. Start %s by %s: %d week%s, $%d, yields %d, %d%% success.\n%s" % [
			plant.get("name", "a plant"),
			profile.get("method", "propagation"),
			int(profile.get("weeks", 1)),
			_plural_suffix(int(profile.get("weeks", 1))),
			int(profile.get("cost", 0)),
			int(profile.get("yield", 1)),
			int(round(float(profile.get("success_chance", 0.0)) * 100.0)),
			profile.get("notes", "")
		]
		start_propagation_button.disabled = cash < int(profile.get("cost", 0))
		start_propagation_button.text = "Start Bench Tray"
		return
	var plant_in_tray := _find_plant(propagation_tray.get("plant_id", ""))
	propagation_status_label.text = "%s tray: %s, %d week%s left. Expected yield %d; success chance %d%%." % [
		plant_in_tray.get("name", "Propagation"),
		propagation_tray.get("method", "propagation"),
		int(propagation_tray.get("weeks_remaining", 0)),
		_plural_suffix(int(propagation_tray.get("weeks_remaining", 0))),
		int(propagation_tray.get("yield", 1)),
		int(round(float(propagation_tray.get("success_chance", 0.0)) * 100.0))
	]
	start_propagation_button.disabled = true
	start_propagation_button.text = "Bench Busy"


func _render_customers() -> void:
	for child in customer_list.get_children():
		child.queue_free()
	for customer in customers:
		var label := Label.new()
		label.text = "%s, %s  |  Budget $%d\nWants: %s\n%s" % [
			customer.get("display_name", "Customer"),
			customer.get("role", "regular"),
			int(customer.get("budget", 0)),
			", ".join(customer.get("taste", [])),
			customer.get("market_hint", "")
		]
		var memory := _latest_relationship_note(customer.get("id", ""))
		if not memory.is_empty():
			label.text = "%s\nNote: %s" % [label.text, memory]
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size = Vector2(0, 108)
		customer_list.add_child(label)


func _recommend_plant(plant_id: String) -> void:
	selected_plant_id = plant_id
	var plant := _find_plant(plant_id)
	if plant.is_empty():
		return
	var signal_data := _current_signal()
	var stock_available := int(plant.get("starting_stock", 0))
	if stock_available <= 0:
		outcome_label.text = "%s has an empty bench tag. The regulars noticed the idea, but no sale happened." % plant.get("name", "That plant")
		_add_log("Recommended an empty %s bench; no one could buy it." % plant.get("name", "plant"))
		_refresh_all()
		return

	var lines: Array[String] = []
	var sold_count := 0
	var sale_total := 0
	var reputation_total := 0
	for customer in customers:
		var fit := _score_customer_fit(plant, customer, signal_data)
		var outcome := _customer_recommendation_outcome(plant, customer, fit, stock_available - sold_count)
		lines.append(outcome.get("line", ""))
		var customer_note: String = outcome.get("note", "")
		if not customer_note.is_empty():
			_remember_customer_note(customer.get("id", ""), customer_note)
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
		_plural_suffix(sold_count),
		sale_total,
		reputation_total
	])
	outcome_label.text = _recommendation_text(plant, signal_data, lines, sold_count, sale_total, reputation_total)
	_add_log("Recommended %s to the regulars: %d sale%s, %+d reputation." % [
		plant.get("name", "a plant"),
		sold_count,
		_plural_suffix(sold_count),
		reputation_total
	])
	_refresh_all()


func _score_customer_fit(plant: Dictionary, customer: Dictionary, signal_data: Dictionary) -> Dictionary:
	var traits: Array = plant.get("traits", [])
	var price := int(plant.get("price", 0))
	var budget := int(customer.get("budget", 0))
	var taste_score := _trait_score(traits, customer.get("taste", []))
	var constraint_score := _constraint_score(plant, customer.get("garden_constraints", []))
	var market_score := _trait_score(traits, signal_data.get("points_to_traits", []))
	var risk_score := _trait_score(traits, signal_data.get("risk_traits", []))
	var hint_score := _hint_trait_score(traits, customer.get("market_hint", ""))
	var budget_score := 0
	if price <= budget:
		budget_score = 2
	elif price <= budget + 4:
		budget_score = 0
	else:
		budget_score = -3
	var total := (taste_score * 2) + (constraint_score * 2) + market_score + hint_score + budget_score - (risk_score * 2)
	return {
		"total": total,
		"taste": taste_score,
		"constraints": constraint_score,
		"market": market_score,
		"risk": risk_score,
		"hint": hint_score,
		"budget": budget_score
	}


func _customer_recommendation_outcome(plant: Dictionary, customer: Dictionary, fit: Dictionary, remaining_stock: int) -> Dictionary:
	var customer_name: String = customer.get("display_name", "Customer")
	var price := int(plant.get("price", 0))
	var total := int(fit.get("total", 0))
	var over_budget := price > int(customer.get("budget", 0)) + 4
	if remaining_stock <= 0:
		return {
			"sold": false,
			"cash": 0,
			"reputation": 0,
			"line": "%s: interested, but the bench was empty." % customer_name,
			"note": "remembered the missing stock"
		}
	if over_budget:
		return {
			"sold": false,
			"cash": 0,
			"reputation": 0,
			"line": "%s: passed; %s strained the $%d budget." % [customer_name, plant.get("name", "it"), int(customer.get("budget", 0))],
			"note": "budget matters more than the prettiest tag"
		}
	if total >= 7:
		return {
			"sold": true,
			"cash": price + 4,
			"reputation": 2,
			"line": "%s: sold gladly. Taste, site, and signal all lined up." % customer_name,
			"note": "trusted the %s recommendation" % plant.get("name", "plant")
		}
	if total >= 4:
		return {
			"sold": true,
			"cash": price,
			"reputation": 1,
			"line": "%s: sold after a care warning. Good enough, not perfect." % customer_name,
			"note": "accepted %s with a care warning" % plant.get("name", "the plant")
		}
	if total >= 1:
		return {
			"sold": false,
			"cash": 0,
			"reputation": 0,
			"line": "%s: did not buy, but learned why %s was a maybe." % [customer_name, plant.get("name", "it")],
			"note": "appreciated the honest maybe"
		}
	return {
		"sold": false,
		"cash": 0,
		"reputation": -1,
		"line": "%s: walked away; the recommendation fought the garden." % customer_name,
		"note": "will need a better fit next time"
	}


func _recommendation_text(plant: Dictionary, signal_data: Dictionary, lines: Array[String], sold_count: int, sale_total: int, reputation_total: int) -> String:
	return "%s against %s: %d sold, $%d, %+d reputation.\n%s" % [
		plant.get("name", "The plant"),
		signal_data.get("source", "the market signal"),
		sold_count,
		sale_total,
		reputation_total,
		"\n".join(lines)
	]


func _on_next_signal_button_pressed() -> void:
	var signals: Array = region.get("market_signals", [])
	if signals.is_empty():
		return
	selected_signal_index = (selected_signal_index + 1) % signals.size()
	_render_signal()


func _on_advance_week_button_pressed() -> void:
	var closing_week := week
	var cash_before_ledger := cash
	var reputation_before_ledger := reputation
	var plant := _find_plant(selected_plant_id)
	var outcome := _best_outcome_for(plant)
	var propagation_text := _process_propagation_week()
	var market_cash_bonus := int(outcome.get("cash_bonus", 0))
	var market_reputation_bonus := int(outcome.get("reputation_bonus", 0))
	cash += market_cash_bonus
	reputation += market_reputation_bonus
	outcome_label.text = _ledger_text(
		closing_week,
		cash_before_ledger,
		reputation_before_ledger,
		market_cash_bonus,
		market_reputation_bonus,
		outcome,
		propagation_text
	)
	_add_log("Ledger closed week %d: %s" % [closing_week, outcome.get("id", "quiet_week")])
	week += 1
	_reset_week_tracking()
	_refresh_all()


func _on_start_propagation_button_pressed() -> void:
	if not propagation_tray.is_empty():
		return
	var plant := _find_plant(selected_plant_id)
	var profile := _propagation_profile(plant)
	if plant.is_empty() or profile.is_empty():
		return
	var cost := int(profile.get("cost", 0))
	if cash < cost:
		outcome_label.text = "The bench stayed empty. You need $%d to start %s." % [cost, plant.get("name", "that tray")]
		return
	cash -= cost
	weekly_bench_spend += cost
	propagation_tray = {
		"plant_id": plant.get("id", ""),
		"method": profile.get("method", "propagation"),
		"weeks_remaining": int(profile.get("weeks", 1)),
		"yield": int(profile.get("yield", 1)),
		"success_chance": float(profile.get("success_chance", 0.75))
	}
	outcome_label.text = "You set a %s tray on the bench. It will need %d week%s before it can join inventory." % [
		plant.get("name", "plant"),
		int(propagation_tray.get("weeks_remaining", 1)),
		_plural_suffix(int(propagation_tray.get("weeks_remaining", 1)))
	]
	_add_log("Started %s by %s for $%d." % [plant.get("name", "a plant"), propagation_tray.get("method", "propagation"), cost])
	_refresh_all()


func _process_propagation_week() -> String:
	if propagation_tray.is_empty():
		return ""
	propagation_tray["weeks_remaining"] = int(propagation_tray.get("weeks_remaining", 0)) - 1
	if int(propagation_tray.get("weeks_remaining", 0)) > 0:
		var growing_plant := _find_plant(propagation_tray.get("plant_id", ""))
		return "The %s tray held steady on the bench. %d week%s left." % [
			growing_plant.get("name", "propagation"),
			int(propagation_tray.get("weeks_remaining", 0)),
			_plural_suffix(int(propagation_tray.get("weeks_remaining", 0)))
		]
	var plant := _find_plant(propagation_tray.get("plant_id", ""))
	var yield_count := int(propagation_tray.get("yield", 1))
	var success_chance := float(propagation_tray.get("success_chance", 0.75))
	var succeeded := randf() <= success_chance
	propagation_tray = {}
	if succeeded:
		plant["starting_stock"] = int(plant.get("starting_stock", 0)) + yield_count
		_add_log("Propagation finished: %s added %d stock." % [plant.get("name", "tray"), yield_count])
		return "The bench paid off: %d %s starts rooted cleanly and joined inventory." % [
			yield_count,
			plant.get("name", "plant")
		]
	_add_log("Propagation failed before saleable stock.")
	return "The bench disappointed you this week. The tray stayed green at the edges, then gave up before it became saleable."


func _best_outcome_for(plant: Dictionary) -> Dictionary:
	var best := {}
	var best_score := -1
	for outcome in region.get("week_outcomes", []):
		var score := _trait_score(plant.get("traits", []), outcome.get("trigger_traits", []))
		if score > best_score:
			best = outcome
			best_score = score
	return best


func _ledger_text(closing_week: int, cash_before_ledger: int, reputation_before_ledger: int, market_cash_bonus: int, market_reputation_bonus: int, outcome: Dictionary, propagation_text: String) -> String:
	var inventory_total := _inventory_total()
	var cash_delta := cash - cash_before_ledger
	var reputation_delta := reputation - reputation_before_ledger
	var market_learning := _market_learning_text()
	var customer_memory := _relationship_summary()
	var recommendation_summary := _recommendation_summary()
	var propagation_summary := propagation_text
	if propagation_summary.is_empty():
		propagation_summary = _propagation_ledger_status()
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
		inventory_total,
		weekly_plants_sold,
		market_learning,
		customer_memory,
		recommendation_summary,
		propagation_summary,
		consequence
	]


func _market_learning_text() -> String:
	var signal_data := _current_signal()
	var points_to: Array = signal_data.get("points_to_traits", [])
	var risks: Array = signal_data.get("risk_traits", [])
	var text := "%s pointed toward %s" % [
		signal_data.get("source", "The signal"),
		", ".join(points_to)
	]
	if not risks.is_empty():
		text = "%s and warned against %s" % [text, ", ".join(risks)]
	return "%s (%d%% uncertain)." % [text, int(float(signal_data.get("uncertainty", 0.0)) * 100.0)]


func _relationship_summary() -> String:
	if weekly_customer_notes.is_empty():
		return "No new regular notes."
	var clipped := weekly_customer_notes.slice(0, min(2, weekly_customer_notes.size()))
	return " | ".join(clipped)


func _recommendation_summary() -> String:
	if weekly_recommendations.is_empty():
		return "Recommendations: none recorded."
	return "Recommendations: %s." % " | ".join(weekly_recommendations.slice(0, min(2, weekly_recommendations.size())))


func _propagation_ledger_status() -> String:
	if propagation_tray.is_empty():
		return "bench idle."
	var plant := _find_plant(propagation_tray.get("plant_id", ""))
	return "%s tray has %d week%s left." % [
		plant.get("name", "active"),
		int(propagation_tray.get("weeks_remaining", 0)),
		_plural_suffix(int(propagation_tray.get("weeks_remaining", 0)))
	]


func _inventory_total() -> int:
	var total := 0
	for plant in plants:
		total += int(plant.get("starting_stock", 0))
	return total


func _reset_week_tracking() -> void:
	weekly_customer_notes = []
	weekly_recommendations = []
	weekly_cash_from_sales = 0
	weekly_reputation_delta = 0
	weekly_bench_spend = 0
	weekly_plants_sold = 0


func _current_signal() -> Dictionary:
	var signals: Array = region.get("market_signals", [])
	if signals.is_empty():
		return {}
	return signals[selected_signal_index % signals.size()]


func _find_plant(plant_id: String) -> Dictionary:
	for plant in plants:
		if plant.get("id", "") == plant_id:
			return plant
	return {}


func _propagation_profile(plant: Dictionary) -> Dictionary:
	return plant.get("propagation", {})


func _trait_score(plant_traits: Array, desired_traits: Array) -> int:
	var score := 0
	for plant_trait in plant_traits:
		if desired_traits.has(plant_trait):
			score += 1
	return score


func _constraint_score(plant: Dictionary, constraints: Array) -> int:
	var score := 0
	var traits: Array = plant.get("traits", [])
	var care_needs: Dictionary = plant.get("care_needs", {})
	var care_text := "%s %s %s" % [
		care_needs.get("water", ""),
		care_needs.get("light", ""),
		care_needs.get("difficulty", "")
	]
	for constraint in constraints:
		var text := String(constraint).to_lower()
		if _has_any(text, ["porch", "step", "bucket"]) and traits.has("porch-friendly"):
			score += 1
		if _has_any(text, ["shade", "moss", "north"]) and (traits.has("shade") or traits.has("damp-tolerant")):
			score += 1
		if _has_any(text, ["overwater", "damp", "mop", "clay"]) and (traits.has("damp-tolerant") or care_text.contains("moist")):
			score += 1
		if _has_any(text, ["forget", "neglect", "simple"]) and (traits.has("low-effort") or traits.has("hardy") or care_text.contains("forgiving")):
			score += 1
		if _has_any(text, ["children", "school", "stories"]) and (traits.has("story-rich") or traits.has("hardy") or traits.has("pollinator")):
			score += 1
		if _has_any(text, ["sun"]) and care_text.contains("sun"):
			score += 1
		if _has_any(text, ["forget", "neglect", "frost"]) and (traits.has("tender") or traits.has("warmth-loving")):
			score -= 1
	return score


func _hint_trait_score(plant_traits: Array, hint: String) -> int:
	var score := 0
	var lowered := hint.to_lower()
	for plant_trait in plant_traits:
		var normalized := String(plant_trait).replace("-", " ").to_lower()
		for word in normalized.split(" ", false):
			if word.length() >= 4 and lowered.contains(word):
				score += 1
				break
	return min(score, 2)


func _has_any(text: String, needles: Array[String]) -> bool:
	for needle in needles:
		if text.contains(needle):
			return true
	return false


func _plural_suffix(amount: int) -> String:
	if amount == 1:
		return ""
	return "s"


func _add_log(message: String) -> void:
	log_lines.push_front(message)
	log_lines = log_lines.slice(0, 5)
	_render_log()


func _render_log() -> void:
	log_label.text = "\n".join(log_lines)


func _remember_customer_note(customer_id: String, note: String) -> void:
	if not relationship_notes.has(customer_id):
		relationship_notes[customer_id] = []
	var notes: Array = relationship_notes[customer_id]
	notes.push_front(note)
	relationship_notes[customer_id] = notes.slice(0, 3)


func _latest_relationship_note(customer_id: String) -> String:
	if not relationship_notes.has(customer_id):
		return ""
	var notes: Array = relationship_notes[customer_id]
	if notes.is_empty():
		return ""
	return notes[0]


func _on_close_button_pressed() -> void:
	close_station()
