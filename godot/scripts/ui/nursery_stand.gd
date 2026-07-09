extends Control

signal closed

const PLANTS_PATH := "res://data/plants/starter_plants.json"
const CUSTOMERS_PATH := "res://data/customers/hush_arbor_archetypes.json"
const REGION_PATH := "res://data/regions/hush_arbor.json"
const DIALOGUE_PATH := "res://data/dialogue/writing_sample_pack.json"
const NurseryRunState := preload("res://scripts/core/nursery_run_state.gd")
const SAVE_FILE_NAME := "garden_nursery_vertical_slice_save.json"
const SAVE_PATH := "user://%s" % SAVE_FILE_NAME
const SAVE_FORMAT := "garden-nursery.save.v1"

var run_state: NurseryRunState
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
@onready var restock_button: Button = %RestockButton
@onready var log_label: Label = %LogText
@onready var next_signal_button: Button = %NextSignalButton
@onready var advance_week_button: Button = %AdvanceWeekButton
@onready var reset_run_button: Button = %ResetRunButton
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
	_load_saved_state()
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
	_save_run_state()
	visible = false
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		close_station()
		get_viewport().set_input_as_handled()


func _load_data() -> void:
	run_state = NurseryRunState.new()
	var region := _read_json(REGION_PATH)
	var dialogue := _read_json(DIALOGUE_PATH)
	var plants: Array = _read_json(PLANTS_PATH).get("plants", [])
	var customers: Array = _read_json(CUSTOMERS_PATH).get("customers", [])
	run_state.setup(plants, customers, region, dialogue)


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
	restock_button.focus_mode = Control.FOCUS_ALL
	advance_week_button.focus_mode = Control.FOCUS_ALL
	reset_run_button.focus_mode = Control.FOCUS_ALL
	close_button.focus_mode = Control.FOCUS_ALL


func _refresh_all() -> void:
	week_label.text = str(run_state.week)
	cash_label.text = "$%d" % run_state.cash
	reputation_label.text = str(run_state.reputation)
	region_label.text = "Hush Arbor roadside yard | %s" % _calendar_header_text()
	_render_signal()
	_render_inventory()
	_render_customers()
	_render_propagation_bench()
	_render_restock_button()
	_render_log()
	_apply_station_mode()


func _apply_station_mode() -> void:
	var is_signal := station_mode == "signal_board" or station_mode == "all"
	var is_stand := station_mode == "plant_stand" or station_mode == "all"
	var is_bench := station_mode == "propagation_bench" or station_mode == "all"
	var is_ledger := station_mode == "ledger" or station_mode == "all"
	var is_journal := station_mode == "journal"

	signal_panel.visible = is_signal
	inventory_panel.visible = is_stand or is_bench
	customer_panel.visible = is_stand
	outcome_panel.visible = is_bench or is_ledger or is_journal or station_mode == "all"
	board_row.visible = signal_panel.visible or inventory_panel.visible
	lower_row.visible = customer_panel.visible or outcome_panel.visible

	next_signal_button.visible = is_signal
	start_propagation_button.visible = is_bench or station_mode == "all"
	restock_button.visible = is_stand or station_mode == "all"
	propagation_heading.visible = is_bench or station_mode == "all"
	propagation_status_label.visible = is_bench or station_mode == "all"
	advance_week_button.visible = is_ledger or station_mode == "all"
	outcome_heading.text = "Ledger"
	if is_journal:
		outcome_heading.text = "Discovery Journal"
	elif is_bench and not is_ledger:
		outcome_heading.text = "Propagation Bench"
	elif station_mode == "all":
		outcome_heading.text = "Week Outcome"
	if is_journal:
		_render_journal()


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
		"journal":
			close_button.grab_focus()
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
		"journal":
			return "Discovery Journal"
		_:
			return "Foothill Plant House"


func _render_signal() -> void:
	var signals: Array = run_state.region.get("market_signals", [])
	if signals.is_empty():
		return
	var signal_data: Dictionary = run_state.current_signal()
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
	for plant in run_state.plants:
		var button := Button.new()
		button.text = "%s  $%d  Stock %d  %s\n%s\n%s" % [
			plant.get("name", "Unnamed plant"),
			int(plant.get("price", 0)),
			int(plant.get("starting_stock", 0)),
			run_state.restock_margin_text(plant),
			", ".join(plant.get("traits", [])),
			_plant_care_text(plant)
		]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size = Vector2(0, 96)
		button.focus_mode = Control.FOCUS_ALL
		button.pressed.connect(_recommend_plant.bind(plant.get("id", "")))
		inventory_list.add_child(button)


func _render_propagation_bench() -> void:
	var lines: Array[String] = ["Propagation queue: %s." % run_state.propagation_slots_label()]
	lines.append_array(run_state.propagation_status_lines())
	var plant := _find_plant(run_state.selected_plant_id)
	var profile := _propagation_profile(plant)
	if plant.is_empty() or profile.is_empty():
		lines.append("Choose a plant to see propagation options.")
		propagation_status_label.text = "\n".join(lines)
		start_propagation_button.disabled = true
		return
	lines.append("Ready: %s by %s: %d week%s, $%d, yields %d, %d%% success.\n%s" % [
		plant.get("name", "a plant"),
		profile.get("method", "propagation"),
		int(profile.get("weeks", 1)),
		_plural_suffix(int(profile.get("weeks", 1))),
		int(profile.get("cost", 0)),
		int(profile.get("yield", 1)),
		int(round(float(profile.get("success_chance", 0.0)) * 100.0)),
		profile.get("notes", "")
	])
	propagation_status_label.text = "\n".join(lines)
	var cost := int(profile.get("cost", 0))
	start_propagation_button.disabled = run_state.cash < cost or not run_state.has_open_propagation_slot()
	start_propagation_button.text = "Start Tray (%d/%d)" % [
		run_state.active_propagation_count(),
		run_state.propagation_capacity
	]
	_render_restock_button()


func _render_customers() -> void:
	for child in customer_list.get_children():
		child.queue_free()
	for customer in run_state.customers:
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
		label.text = "%s\n%s" % [label.text, _customer_memory_text(customer)]
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size = Vector2(0, 146)
		customer_list.add_child(label)


func _render_journal() -> void:
	var sections: Array[String] = [
		_journal_plants_text(),
		_journal_customers_text(),
		_journal_signals_text(),
		_journal_reflections_text()
	]
	outcome_label.text = "\n\n".join(sections)


func _journal_plants_text() -> String:
	var known := _known_discoveries("plants")
	if known.is_empty():
		return "Plants\n- No plant tags studied yet. Recommend a plant to ink the first note."
	var lines: Array[String] = ["Plants"]
	var shown := 0
	for plant_id in known:
		var plant: Dictionary = _find_plant(plant_id)
		if plant.is_empty():
			continue
		lines.append("- %s: %s. %s %s" % [
			plant.get("name", "Unknown plant"),
			", ".join(plant.get("traits", [])),
			_plant_care_text(plant),
			_clip_text(plant.get("market_notes", "Notes still uncertain."), 92)
		])
		shown += 1
		if shown >= 4:
			break
	var hidden_count: int = int(max(0, run_state.plants.size() - known.size()))
	if hidden_count > 0:
		lines.append("- %d plant tag%s still just look like handwriting and hope." % [hidden_count, _plural_suffix(hidden_count)])
	return "\n".join(lines)


func _journal_customers_text() -> String:
	var known := _known_discoveries("customers")
	if known.is_empty():
		return "Customers\n- The regulars are only names so far. Recommend a plant to learn what matters."
	var lines: Array[String] = ["Customers"]
	for customer_id in known:
		var customer: Dictionary = _find_customer(customer_id)
		if customer.is_empty():
			continue
		var note := _latest_relationship_note(customer_id)
		if note.is_empty():
			note = "needs still penciled in"
		lines.append("- %s, %s: %s %s" % [
			customer.get("display_name", "Customer"),
			customer.get("role", "regular"),
			_clip_text(note, 86),
			_clip_text(_customer_memory_text(customer), 120)
		])
	var hidden_count: int = int(max(0, run_state.customers.size() - known.size()))
	if hidden_count > 0:
		lines.append("- %d regular%s not understood yet." % [hidden_count, _plural_suffix(hidden_count)])
	return "\n".join(lines)


func _journal_signals_text() -> String:
	var known := _known_discoveries("signals")
	if known.is_empty():
		return "Market Reads\n- No posted signal has been copied into the notebook."
	var lines: Array[String] = ["Market Reads"]
	for signal_id in known:
		var signal_data: Dictionary = _find_signal(signal_id)
		if signal_data.is_empty():
			continue
		lines.append("- %s: %s Points toward %s." % [
			signal_data.get("source", "signal").capitalize(),
			_clip_text(signal_data.get("text", ""), 86),
			", ".join(signal_data.get("points_to_traits", []))
		])
	var hidden_count: int = int(max(0, run_state.region.get("market_signals", []).size() - known.size()))
	if hidden_count > 0:
		lines.append("- %d market note%s still unread." % [hidden_count, _plural_suffix(hidden_count)])
	return "\n".join(lines)


func _journal_reflections_text() -> String:
	if run_state.journal_week_reflections.is_empty():
		return "Week Reflections\n- No week has been closed in the ledger yet."
	var lines: Array[String] = ["Week Reflections"]
	for reflection in run_state.journal_week_reflections.slice(0, min(3, run_state.journal_week_reflections.size())):
		lines.append("- %s" % reflection)
	return "\n".join(lines)


func _recommend_plant(plant_id: String) -> void:
	var result := run_state.recommend_plant(plant_id)
	if result.is_empty():
		return
	outcome_label.text = result.get("outcome_text", "")
	var log_line: String = result.get("log", "")
	if not log_line.is_empty():
		_add_log(log_line)
	_save_run_state()
	_refresh_all()


func _on_next_signal_button_pressed() -> void:
	if not run_state.next_signal():
		return
	_save_run_state()
	_render_signal()


func _on_advance_week_button_pressed() -> void:
	var result := run_state.advance_week()
	outcome_label.text = result.get("outcome_text", "")
	var log_line: String = result.get("log", "")
	if not log_line.is_empty():
		_add_log(log_line)
	_save_run_state()
	_refresh_all()


func _on_start_propagation_button_pressed() -> void:
	var result := run_state.start_propagation()
	if result.is_empty():
		return
	outcome_label.text = result.get("outcome_text", "")
	var log_line: String = result.get("log", "")
	if not log_line.is_empty():
		_add_log(log_line)
	_save_run_state()
	_refresh_all()


func _on_restock_button_pressed() -> void:
	var result := run_state.restock_selected_plant()
	if result.is_empty():
		return
	outcome_label.text = result.get("outcome_text", "")
	var log_line: String = result.get("log", "")
	if not log_line.is_empty():
		_add_log(log_line)
	_save_run_state()
	_refresh_all()


func _load_saved_state() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		_add_log("Save data could not be opened, so a new run is ready.")
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY or parsed.get("format", "") != SAVE_FORMAT:
		_add_log("Save data looked wrong, so a new run is ready.")
		return
	var saved_state: Dictionary = parsed.get("state", {})
	if not run_state.apply_saved_state(saved_state):
		_add_log("Save data was empty, so a new run is ready.")
		return
	_add_log("Loaded saved vertical-slice run from week %d." % run_state.week)


func _save_run_state() -> void:
	var save_data := {
		"format": SAVE_FORMAT,
		"saved_at_unix": int(Time.get_unix_time_from_system()),
		"state": run_state.save_state_snapshot()
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Could not write save file: %s" % SAVE_PATH)
		return
	file.store_string(JSON.stringify(save_data, "\t"))


func _known_discoveries(kind: String) -> Array:
	return run_state.known_discoveries(kind)


func _current_signal() -> Dictionary:
	return run_state.current_signal()


func _find_plant(plant_id: String) -> Dictionary:
	return run_state.find_plant(plant_id)


func _find_customer(customer_id: String) -> Dictionary:
	return run_state.find_customer(customer_id)


func _find_signal(signal_id: String) -> Dictionary:
	return run_state.find_signal(signal_id)


func _propagation_profile(plant: Dictionary) -> Dictionary:
	return run_state.propagation_profile(plant)


func _render_restock_button() -> void:
	var plant := _find_plant(run_state.selected_plant_id)
	if plant.is_empty():
		restock_button.disabled = true
		restock_button.text = "Order Stock"
		return
	var quote := run_state.restock_quote(plant)
	restock_button.text = "Order %d for $%d" % [int(quote.get("quantity", 0)), int(quote.get("cost", 0))]
	restock_button.disabled = not bool(quote.get("can_order", false))


func _plant_care_text(plant: Dictionary) -> String:
	return run_state.plant_care_text(plant)


func _customer_memory_text(customer: Dictionary) -> String:
	return run_state.customer_memory_text(customer)


func _calendar_header_text() -> String:
	var entry := run_state.current_calendar_entry()
	if entry.is_empty():
		return "weather unposted"
	return "%s, %s" % [entry.get("season", "season"), entry.get("weather", "weather")]


func _clip_text(text: String, max_length: int) -> String:
	return run_state.clip_text(text, max_length)


func _plural_suffix(amount: int) -> String:
	return run_state.plural_suffix(amount)


func _add_log(message: String) -> void:
	run_state.add_log(message)
	_render_log()


func _render_log() -> void:
	log_label.text = "\n".join(run_state.log_lines)


func _latest_relationship_note(customer_id: String) -> String:
	return run_state.latest_relationship_note(customer_id)


func _on_reset_run_button_pressed() -> void:
	var dir := DirAccess.open("user://")
	if dir != null and dir.file_exists(SAVE_FILE_NAME):
		dir.remove(SAVE_FILE_NAME)
	_load_data()
	outcome_label.text = "New run started. The old ledger page is cleared for testing."
	_add_log("Reset vertical-slice save data.")
	_save_run_state()
	_refresh_all()
	_grab_station_focus()


func _on_close_button_pressed() -> void:
	close_station()
