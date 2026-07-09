extends Area2D

@export var station_id := ""
@export var station_name := "Nursery station"
@export var action_label := "Use station"
@export var prompt_offset := Vector2(-170, -150)


func get_station_id() -> String:
	return station_id


func get_station_name() -> String:
	return station_name


func get_prompt_text() -> String:
	return "%s\nPress Confirm to %s" % [station_name, action_label]


func get_prompt_position() -> Vector2:
	return global_position + prompt_offset
