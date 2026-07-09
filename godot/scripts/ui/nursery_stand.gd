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
	_add_log("Plant stand recommended %s after reading the %s." % [plant.get("name", "a plant"), signal_data.get("source", "signal")])
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
	var propagation_text := _process_propagation_week()
	cash += int(outcome.get("cash_bonus", 0))
	reputation += int(outcome.get("reputation_bonus", 0))
	var outcome_text: String = outcome.get("text", "The week ended quietly. The ledger learned less than you did.")
	if not propagation_text.is_empty():
		outcome_text = "%s\n\n%s" % [outcome_text, propagation_text]
	outcome_label.text = outcome_text
	_add_log("Ledger closed week %d: %s" % [week - 1, outcome.get("id", "quiet_week")])
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


func _on_close_button_pressed() -> void:
	close_station()
