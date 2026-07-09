extends Node2D

signal station_activated(station_id: String)

var nearby_stations: Array[Area2D] = []
var current_station: Area2D
var overlay_open := false

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
	if overlay_open or current_station == null:
		prompt_container.visible = false
		return
	prompt_label.text = current_station.get_prompt_text()
	prompt_container.global_position = current_station.get_prompt_position()
	prompt_container.visible = true


func _activate_current_station() -> void:
	if current_station == null:
		return
	var station_id: String = current_station.get_station_id()
	var station_name: String = current_station.get_station_name()
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
