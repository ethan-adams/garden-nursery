extends Control

signal closed

const PLANTS_PATH := "res://data/plants/starter_plants.json"
const CUSTOMERS_PATH := "res://data/customers/hush_arbor_archetypes.json"
const REGION_PATH := "res://data/regions/hush_arbor.json"
const DIALOGUE_PATH := "res://data/dialogue/writing_sample_pack.json"
const NurseryRules := preload("res://scripts/core/nursery_rules.gd")
const SAVE_FILE_NAME := "garden_nursery_vertical_slice_save.json"
const SAVE_PATH := "user://%s" % SAVE_FILE_NAME
const SAVE_FORMAT := "garden-nursery.save.v1"

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
var selected_discoveries: Dictionary = {}
var journal_week_reflections: Array[String] = []
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
	relationship_notes = {}
	selected_discoveries = _fresh_discoveries()
	journal_week_reflections = []
	propagation_tray = {}
	_reset_week_tracking()
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
	reset_run_button.focus_mode = Control.FOCUS_ALL
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
	var is_journal := station_mode == "journal"

	signal_panel.visible = is_signal
	inventory_panel.visible = is_stand or is_bench
	customer_panel.visible = is_stand
	outcome_panel.visible = is_bench or is_ledger or is_journal or station_mode == "all"
	board_row.visible = signal_panel.visible or inventory_panel.visible
	lower_row.visible = customer_panel.visible or outcome_panel.visible

	next_signal_button.visible = is_signal
	start_propagation_button.visible = is_bench or station_mode == "all"
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
		lines.append("- %s: %s. %s" % [
			plant.get("name", "Unknown plant"),
			", ".join(plant.get("traits", [])),
			_clip_text(plant.get("market_notes", "Notes still uncertain."), 92)
		])
		shown += 1
		if shown >= 4:
			break
	var hidden_count: int = int(max(0, plants.size() - known.size()))
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
		lines.append("- %s, %s: %s." % [
			customer.get("display_name", "Customer"),
			customer.get("role", "regular"),
			_clip_text(note, 86)
		])
	var hidden_count: int = int(max(0, customers.size() - known.size()))
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
	var hidden_count: int = int(max(0, region.get("market_signals", []).size() - known.size()))
	if hidden_count > 0:
		lines.append("- %d market note%s still unread." % [hidden_count, _plural_suffix(hidden_count)])
	return "\n".join(lines)


func _journal_reflections_text() -> String:
	if journal_week_reflections.is_empty():
		return "Week Reflections\n- No week has been closed in the ledger yet."
	var lines: Array[String] = ["Week Reflections"]
	for reflection in journal_week_reflections.slice(0, min(3, journal_week_reflections.size())):
		lines.append("- %s" % reflection)
	return "\n".join(lines)


func _recommend_plant(plant_id: String) -> void:
	selected_plant_id = plant_id
	var plant := _find_plant(plant_id)
	if plant.is_empty():
		return
	var signal_data := _current_signal()
	_remember_discovery("plants", plant.get("id", ""))
	_remember_discovery("signals", signal_data.get("id", ""))
	var stock_available := int(plant.get("starting_stock", 0))
	if stock_available <= 0:
		outcome_label.text = "%s has an empty bench tag. The regulars noticed the idea, but no sale happened." % plant.get("name", "That plant")
		_add_log("Recommended an empty %s bench; no one could buy it." % plant.get("name", "plant"))
		_save_run_state()
		_refresh_all()
		return

	var lines: Array[String] = []
	var sold_count := 0
	var sale_total := 0
	var reputation_total := 0
	for customer in customers:
		_remember_discovery("customers", customer.get("id", ""))
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
	_save_run_state()
	_refresh_all()


func _score_customer_fit(plant: Dictionary, customer: Dictionary, signal_data: Dictionary) -> Dictionary:
	return NurseryRules.score_customer_fit(plant, customer, signal_data)


func _customer_recommendation_outcome(plant: Dictionary, customer: Dictionary, fit: Dictionary, remaining_stock: int) -> Dictionary:
	return NurseryRules.customer_recommendation_outcome(plant, customer, fit, remaining_stock)


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
	_remember_discovery("signals", _current_signal().get("id", ""))
	_save_run_state()
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
	_remember_week_reflection(closing_week, outcome)
	_add_log("Ledger closed week %d: %s" % [closing_week, outcome.get("id", "quiet_week")])
	week += 1
	_reset_week_tracking()
	_save_run_state()
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
	_save_run_state()
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
	return NurseryRules.best_outcome_for(plant, region.get("week_outcomes", []))


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
	if saved_state.is_empty():
		_add_log("Save data was empty, so a new run is ready.")
		return

	week = max(1, int(saved_state.get("week", week)))
	cash = int(saved_state.get("cash", cash))
	reputation = int(saved_state.get("reputation", reputation))
	selected_signal_index = max(0, int(saved_state.get("selected_signal_index", selected_signal_index)))
	selected_plant_id = saved_state.get("selected_plant_id", selected_plant_id)
	_apply_inventory_stock(saved_state.get("inventory_stock", {}))
	propagation_tray = _sanitize_dictionary(saved_state.get("propagation_tray", {}))
	relationship_notes = _sanitize_relationship_notes(saved_state.get("customer_notes", {}))
	selected_discoveries = _sanitize_discoveries(saved_state.get("discoveries", {}))
	journal_week_reflections = _strings_from(saved_state.get("week_reflections", [])).slice(0, 6)
	_apply_weekly_activity(saved_state.get("weekly_activity", {}))
	if _find_plant(selected_plant_id).is_empty() and not plants.is_empty():
		selected_plant_id = plants[0].get("id", "")
	_add_log("Loaded saved vertical-slice run from week %d." % week)


func _save_run_state() -> void:
	var save_data := {
		"format": SAVE_FORMAT,
		"saved_at_unix": int(Time.get_unix_time_from_system()),
		"state": {
			"week": week,
			"cash": cash,
			"reputation": reputation,
			"selected_signal_index": selected_signal_index,
			"selected_plant_id": selected_plant_id,
			"inventory_stock": _inventory_stock_snapshot(),
			"propagation_tray": propagation_tray,
			"customer_notes": relationship_notes,
			"discoveries": selected_discoveries,
			"week_reflections": journal_week_reflections,
			"weekly_activity": _weekly_activity_snapshot()
		}
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Could not write save file: %s" % SAVE_PATH)
		return
	file.store_string(JSON.stringify(save_data, "\t"))


func _inventory_stock_snapshot() -> Dictionary:
	var snapshot := {}
	for plant in plants:
		snapshot[plant.get("id", "")] = int(plant.get("starting_stock", 0))
	return snapshot


func _apply_inventory_stock(stock_data) -> void:
	if typeof(stock_data) != TYPE_DICTIONARY:
		return
	for plant in plants:
		var plant_id: String = plant.get("id", "")
		if stock_data.has(plant_id):
			plant["starting_stock"] = max(0, int(stock_data.get(plant_id, plant.get("starting_stock", 0))))


func _weekly_activity_snapshot() -> Dictionary:
	return {
		"customer_notes": weekly_customer_notes,
		"recommendations": weekly_recommendations,
		"cash_from_sales": weekly_cash_from_sales,
		"reputation_delta": weekly_reputation_delta,
		"bench_spend": weekly_bench_spend,
		"plants_sold": weekly_plants_sold
	}


func _apply_weekly_activity(activity_data) -> void:
	if typeof(activity_data) != TYPE_DICTIONARY:
		return
	weekly_customer_notes = _strings_from(activity_data.get("customer_notes", []))
	weekly_recommendations = _strings_from(activity_data.get("recommendations", []))
	weekly_cash_from_sales = int(activity_data.get("cash_from_sales", 0))
	weekly_reputation_delta = int(activity_data.get("reputation_delta", 0))
	weekly_bench_spend = int(activity_data.get("bench_spend", 0))
	weekly_plants_sold = int(activity_data.get("plants_sold", 0))


func _sanitize_dictionary(value) -> Dictionary:
	if typeof(value) == TYPE_DICTIONARY:
		return value
	return {}


func _sanitize_relationship_notes(value) -> Dictionary:
	var sanitized := {}
	for customer in customers:
		var customer_id: String = customer.get("id", "")
		sanitized[customer_id] = []
	if typeof(value) != TYPE_DICTIONARY:
		return sanitized
	for customer_id in value.keys():
		sanitized[customer_id] = _strings_from(value.get(customer_id, [])).slice(0, 3)
	return sanitized


func _sanitize_discoveries(value) -> Dictionary:
	var sanitized := _fresh_discoveries()
	if typeof(value) != TYPE_DICTIONARY:
		return sanitized
	for kind in sanitized.keys():
		sanitized[kind] = _strings_from(value.get(kind, []))
	return sanitized


func _fresh_discoveries() -> Dictionary:
	return {
		"plants": [],
		"customers": [],
		"signals": []
	}


func _strings_from(value) -> Array[String]:
	var strings: Array[String] = []
	if typeof(value) != TYPE_ARRAY:
		return strings
	for item in value:
		strings.append(str(item))
	return strings


func _remember_discovery(kind: String, id: String) -> void:
	if id.is_empty():
		return
	if not selected_discoveries.has(kind):
		selected_discoveries[kind] = []
	var known: Array = selected_discoveries[kind]
	if not known.has(id):
		known.append(id)
	selected_discoveries[kind] = known


func _known_discoveries(kind: String) -> Array:
	if not selected_discoveries.has(kind):
		return []
	return selected_discoveries[kind]


func _remember_week_reflection(closing_week: int, outcome: Dictionary) -> void:
	var text := "Week %d: %s" % [
		closing_week,
		_clip_text(outcome.get("text", "The week closed quietly."), 112)
	]
	journal_week_reflections.push_front(text)
	journal_week_reflections = journal_week_reflections.slice(0, 6)


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


func _find_customer(customer_id: String) -> Dictionary:
	for customer in customers:
		if customer.get("id", "") == customer_id:
			return customer
	return {}


func _find_signal(signal_id: String) -> Dictionary:
	for signal_data in region.get("market_signals", []):
		if signal_data.get("id", "") == signal_id:
			return signal_data
	return {}


func _propagation_profile(plant: Dictionary) -> Dictionary:
	return plant.get("propagation", {})


func _trait_score(plant_traits: Array, desired_traits: Array) -> int:
	return NurseryRules.trait_score(plant_traits, desired_traits)


func _constraint_score(plant: Dictionary, constraints: Array) -> int:
	return NurseryRules.constraint_score(plant, constraints)


func _hint_trait_score(plant_traits: Array, hint: String) -> int:
	return NurseryRules.hint_trait_score(plant_traits, hint)


func _has_any(text: String, needles: Array[String]) -> bool:
	for needle in needles:
		if text.contains(needle):
			return true
	return false


func _clip_text(text: String, max_length: int) -> String:
	if text.length() <= max_length:
		return text
	return "%s..." % text.substr(0, max(0, max_length - 3))


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
