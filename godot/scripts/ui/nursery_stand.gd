extends Control

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
var log_lines: Array[String] = []

@onready var week_label: Label = %WeekValue
@onready var cash_label: Label = %CashValue
@onready var reputation_label: Label = %ReputationValue
@onready var signal_source_label: Label = %SignalSource
@onready var signal_text_label: Label = %SignalText
@onready var signal_traits_label: Label = %SignalTraits
@onready var inventory_list: VBoxContainer = %InventoryList
@onready var customer_list: VBoxContainer = %CustomerList
@onready var outcome_label: Label = %OutcomeText
@onready var log_label: Label = %LogText
@onready var next_signal_button: Button = %NextSignalButton
@onready var advance_week_button: Button = %AdvanceWeekButton

func _ready() -> void:
	_load_data()
	_setup_focus()
	_refresh_all()


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
	advance_week_button.focus_mode = Control.FOCUS_ALL


func _refresh_all() -> void:
	week_label.text = str(week)
	cash_label.text = "$%d" % cash
	reputation_label.text = str(reputation)
	_render_signal()
	_render_inventory()
	_render_customers()
	_render_log()


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


func _render_customers() -> void:
	for child in customer_list.get_children():
		child.queue_free()
	for customer in customers:
		var label := Label.new()
		label.text = "%s, %s\n%s" % [
			customer.get("display_name", "Customer"),
			customer.get("role", "regular"),
			customer.get("market_hint", "")
		]
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size = Vector2(0, 82)
		customer_list.add_child(label)


func _recommend_plant(plant_id: String) -> void:
	selected_plant_id = plant_id
	var plant := _find_plant(plant_id)
	if plant.is_empty():
		return
	var signal_data := _current_signal()
	var score: int = _trait_score(plant.get("traits", []), signal_data.get("points_to_traits", []))
	var risk: int = _trait_score(plant.get("traits", []), signal_data.get("risk_traits", []))
	var sale: int = int(plant.get("price", 0)) + (score * 4) - (risk * 2)
	var reputation_delta: int = int(max(1, score + 1 - risk))
	cash += int(max(4, sale))
	reputation += reputation_delta
	plant["starting_stock"] = int(max(0, int(plant.get("starting_stock", 0)) - 1))
	outcome_label.text = _recommendation_text(plant, signal_data, score, risk)
	_add_log("Recommended %s after reading the %s." % [plant.get("name", "a plant"), signal_data.get("source", "signal")])
	_refresh_all()


func _recommendation_text(plant: Dictionary, signal_data: Dictionary, score: int, risk: int) -> String:
	if score > risk:
		return "%s fit the clue. The sale felt earned, not lucky." % plant.get("name", "The plant")
	if risk > score:
		return "%s drew interest, but the signal warned against it. Customers paid, then asked harder questions." % plant.get("name", "The plant")
	return "%s was a fair guess. No one complained, but no one called it wisdom either." % plant.get("name", "The plant")


func _on_next_signal_button_pressed() -> void:
	var signals: Array = region.get("market_signals", [])
	if signals.is_empty():
		return
	selected_signal_index = (selected_signal_index + 1) % signals.size()
	_render_signal()


func _on_advance_week_button_pressed() -> void:
	week += 1
	var plant := _find_plant(selected_plant_id)
	var outcome := _best_outcome_for(plant)
	cash += int(outcome.get("cash_bonus", 0))
	reputation += int(outcome.get("reputation_bonus", 0))
	outcome_label.text = outcome.get("text", "The week ended quietly. The ledger learned less than you did.")
	_add_log("Week %d closed: %s" % [week - 1, outcome.get("id", "quiet_week")])
	_refresh_all()


func _best_outcome_for(plant: Dictionary) -> Dictionary:
	var best := {}
	var best_score := -1
	for outcome in region.get("week_outcomes", []):
		var score := _trait_score(plant.get("traits", []), outcome.get("trigger_traits", []))
		if score > best_score:
			best = outcome
			best_score = score
	return best


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


func _trait_score(plant_traits: Array, desired_traits: Array) -> int:
	var score := 0
	for plant_trait in plant_traits:
		if desired_traits.has(plant_trait):
			score += 1
	return score


func _add_log(message: String) -> void:
	log_lines.push_front(message)
	log_lines = log_lines.slice(0, 5)
	_render_log()


func _render_log() -> void:
	log_label.text = "\n".join(log_lines)
