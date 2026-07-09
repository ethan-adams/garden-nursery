extends CharacterBody2D

@export var move_speed := 178.0
@export var acceleration := 960.0
@export var deceleration := 1180.0
@export var play_bounds := Rect2(145, 185, 990, 470)

var movement_enabled := true


func set_movement_enabled(enabled: bool) -> void:
	movement_enabled = enabled
	if not movement_enabled:
		velocity = Vector2.ZERO

func _physics_process(delta: float) -> void:
	var input_direction := Vector2.ZERO
	if movement_enabled:
		input_direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var target_velocity := input_direction * move_speed
	var rate := acceleration
	if input_direction.is_zero_approx():
		rate = deceleration
	velocity = velocity.move_toward(target_velocity, rate * delta)
	move_and_slide()
	_keep_inside_play_bounds()


func _keep_inside_play_bounds() -> void:
	global_position.x = clampf(global_position.x, play_bounds.position.x, play_bounds.position.x + play_bounds.size.x)
	global_position.y = clampf(global_position.y, play_bounds.position.y, play_bounds.position.y + play_bounds.size.y)
