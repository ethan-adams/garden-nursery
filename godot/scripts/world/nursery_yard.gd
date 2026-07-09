extends Node2D

signal station_activated(station_id: String)

var nearby_stations: Array[Area2D] = []
var current_station: Area2D
var overlay_open := false
var onboarding_seen := {}

const ONBOARDING_FLOW := [
	{
		"station_id": "signal_board",
		"title": "Read the weather and town gossip first.",
		"hint": "The signal board tells you what Hush Arbor wants this week."
	},
	{
		"station_id": "plant_stand",
		"title": "Choose a plant for the regulars.",
		"hint": "Plant cards show price, stock, care, and local fit."
	},
	{
		"station_id": "propagation_bench",
		"title": "Start or check nursery trays.",
		"hint": "Propagation and restock choices prepare future stock."
	},
	{
		"station_id": "ledger",
		"title": "Close the week when the yard work is done.",
		"hint": "The ledger turns sales, weather, stock, and trust into consequences."
	},
	{
		"station_id": "journal",
		"title": "Check the notebook for what you learned.",
		"hint": "The journal keeps plant notes, customer memory, and market reads."
	}
]

@onready var player: CharacterBody2D = $Player
@onready var station_overlay: Control = $StationOverlay/NurseryStand
@onready var prompt_container: PanelContainer = $StationPrompt
@onready var prompt_label: Label = $StationPrompt/PromptMargin/PromptText


func _ready() -> void:
	for station in _station_nodes():
		station.body_entered.connect(_on_station_body_entered.bind(station))
		station.body_exited.connect(_on_station_body_exited.bind(station))
	if station_overlay.has_signal("closed"):
		station_overlay.closed.connect(_on_station_overlay_closed)
	station_overlay.visible = false
	prompt_container.visible = false
	_refresh_station_focus()


func _process(_delta: float) -> void:
	_refresh_station_focus()
	_update_prompt()


func _unhandled_input(event: InputEvent) -> void:
	if overlay_open:
		return
	if current_station == null:
		return
	if event.is_action_pressed("ui_confirm") or event.is_action_pressed("ui_accept"):
		_activate_current_station()
		get_viewport().set_input_as_handled()


func _station_nodes() -> Array[Area2D]:
	var stations: Array[Area2D] = []
	for child in get_children():
		if child is Area2D and child.has_method("get_station_id"):
			stations.append(child)
	return stations


func _on_station_body_entered(body: Node2D, station: Area2D) -> void:
	if body != player:
		return
	if not nearby_stations.has(station):
		nearby_stations.append(station)
	_refresh_station_focus()


func _on_station_body_exited(body: Node2D, station: Area2D) -> void:
	if body != player:
		return
	nearby_stations.erase(station)
	_refresh_station_focus()


func _refresh_station_focus() -> void:
	if nearby_stations.is_empty():
		current_station = null
		return
	var nearest_station := nearby_stations[0]
	var nearest_distance := player.global_position.distance_squared_to(nearest_station.global_position)
	for station in nearby_stations:
		var distance := player.global_position.distance_squared_to(station.global_position)
		if distance < nearest_distance:
			nearest_station = station
			nearest_distance = distance
	current_station = nearest_station


func _update_prompt() -> void:
	if overlay_open:
		prompt_container.visible = false
		return
	var onboarding_step := _current_onboarding_step()
	if current_station == null:
		if onboarding_step.is_empty():
			prompt_container.visible = false
			return
		prompt_label.text = "%s\n%s" % [onboarding_step.get("title", ""), _station_direction_text(onboarding_step.get("station_id", ""))]
		prompt_container.global_position = Vector2(360, 96)
		prompt_container.visible = true
		return
	var prompt_text: String = current_station.get_prompt_text()
	if not onboarding_step.is_empty():
		if current_station.get_station_id() == onboarding_step.get("station_id", ""):
			prompt_text = "%s\n%s" % [onboarding_step.get("hint", ""), prompt_text]
		else:
			prompt_text = "%s\nNext: %s" % [prompt_text, onboarding_step.get("title", "")]
	prompt_label.text = prompt_text
	prompt_container.global_position = current_station.get_prompt_position()
	prompt_container.visible = true


func _activate_current_station() -> void:
	if current_station == null:
		return
	var station_id: String = current_station.get_station_id()
	var station_name: String = current_station.get_station_name()
	onboarding_seen[station_id] = true
	overlay_open = true
	prompt_container.visible = false
	if player.has_method("set_movement_enabled"):
		player.set_movement_enabled(false)
	station_activated.emit(station_id)
	station_overlay.visible = true
	if station_overlay.has_method("open_station"):
		station_overlay.open_station(station_id, station_name)


func _on_station_overlay_closed() -> void:
	overlay_open = false
	station_overlay.visible = false
	if player.has_method("set_movement_enabled"):
		player.set_movement_enabled(true)
	_refresh_station_focus()
	_update_prompt()


func _current_onboarding_step() -> Dictionary:
	for step in ONBOARDING_FLOW:
		var station_id: String = step.get("station_id", "")
		if not bool(onboarding_seen.get(station_id, false)):
			return step
	return {}


func _station_direction_text(station_id: String) -> String:
	match station_id:
		"signal_board":
			return "Walk to the posted board on the left and press Confirm."
		"plant_stand":
			return "Walk to the middle tables and press Confirm."
		"propagation_bench":
			return "Walk to the right-hand bench and press Confirm."
		"ledger":
			return "Walk down to the ledger table and press Confirm."
		"journal":
			return "Walk to the notebook by the lower tables and press Confirm."
		_:
			return "Walk to the next station and press Confirm."
