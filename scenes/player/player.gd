extends CharacterBody2D

const SPEED := 160.0
const JUMP_VELOCITY := -320.0
const GRAVITY := 900.0
const CLIMB_SPEED := 100.0
const ECHO_SCENE := preload("res://scenes/player/echo.tscn")

enum State { IDLE, RUN, JUMP, FALL, CLIMB }

var ladders_in_range: Array[Area2D] = []
var ladders_below_in_range: Array[Area2D] = []
var state: State = State.IDLE
var drop_through_remaining := 0.0
var current_echo: Node2D = null


func _physics_process(delta: float) -> void:
	_update_drop_through(delta)
	if Input.is_action_just_pressed("echo_create"):
		create_echo()

	var horizontal_direction := Input.get_axis("ui_left", "ui_right")
	var vertical_direction := Input.get_axis("ui_up", "ui_down")

	if state == State.CLIMB:
		_handle_climb(delta, horizontal_direction, vertical_direction)
		return

	var can_climb_up := not ladders_in_range.is_empty() and vertical_direction < 0.0
	var can_climb_down := not ladders_below_in_range.is_empty() and vertical_direction > 0.0 and _can_drop_through()
	if can_climb_up or can_climb_down:
		if can_climb_down:
			_start_drop_through()
		state = State.CLIMB
		_handle_climb(delta, horizontal_direction, vertical_direction)
		return

	if not is_on_floor():
		velocity.y += GRAVITY * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = JUMP_VELOCITY

	velocity.x = horizontal_direction * SPEED
	move_and_slide()
	_update_movement_state(horizontal_direction)


func _handle_climb(delta: float, horizontal_direction: float, vertical_direction: float) -> void:
	if ladders_in_range.is_empty() and ladders_below_in_range.is_empty():
		state = State.FALL
		velocity.y = 0.0
		return

	if Input.is_action_just_pressed("jump"):
		state = State.JUMP
		velocity.x = horizontal_direction * SPEED
		velocity.y = JUMP_VELOCITY
		move_and_slide()
		return

	var ladder := _get_active_ladder(vertical_direction)
	if ladder == null:
		state = State.FALL
		return

	global_position.x = ladder.global_position.x
	velocity.x = 0.0
	velocity.y = CLIMB_SPEED if drop_through_remaining > 0.0 and vertical_direction == 0.0 else vertical_direction * CLIMB_SPEED
	move_and_slide()


func _update_movement_state(horizontal_direction: float) -> void:
	if not is_on_floor():
		state = State.JUMP if velocity.y < 0.0 else State.FALL
	elif horizontal_direction != 0.0:
		state = State.RUN
	else:
		state = State.IDLE


func _on_ladder_detector_area_entered(area: Area2D) -> void:
	if area.is_in_group(&"ladder") and not ladders_in_range.has(area):
		ladders_in_range.append(area)


func _on_ladder_detector_area_exited(area: Area2D) -> void:
	if area.is_in_group(&"ladder"):
		ladders_in_range.erase(area)


func _on_ladder_below_detector_area_entered(area: Area2D) -> void:
	if area.is_in_group(&"ladder") and not ladders_below_in_range.has(area):
		ladders_below_in_range.append(area)


func _on_ladder_below_detector_area_exited(area: Area2D) -> void:
	if area.is_in_group(&"ladder"):
		ladders_below_in_range.erase(area)


func _get_active_ladder(vertical_direction: float) -> Area2D:
	if vertical_direction > 0.0 and not ladders_below_in_range.is_empty():
		return ladders_below_in_range[0]
	if not ladders_in_range.is_empty():
		return ladders_in_range[0]
	return null


func _can_drop_through() -> bool:
	var floor_body := $FloorDetector.get_collider() as Node2D
	return floor_body != null and floor_body.is_in_group(&"drop_through_platform")


func _start_drop_through() -> void:
	drop_through_remaining = 0.7
	$CollisionShape2D.set_deferred("disabled", true)


func _update_drop_through(delta: float) -> void:
	if drop_through_remaining <= 0.0:
		return

	drop_through_remaining -= delta
	if drop_through_remaining <= 0.0:
		$CollisionShape2D.set_deferred("disabled", false)


func create_echo() -> void:
	if current_echo != null and is_instance_valid(current_echo):
		current_echo.queue_free()

	current_echo = ECHO_SCENE.instantiate()
	current_echo.global_position = global_position
	get_tree().current_scene.add_child(current_echo)
