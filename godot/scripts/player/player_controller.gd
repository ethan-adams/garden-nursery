extends CharacterBody2D

@export var move_speed := 230.0
@export var acceleration := 14.0

func _physics_process(delta: float) -> void:
	var input_direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var target_velocity := input_direction * move_speed
	velocity = velocity.lerp(target_velocity, min(1.0, acceleration * delta))
	move_and_slide()
