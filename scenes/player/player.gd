extends CharacterBody2D

const SPEED := 160.0
const JUMP_VELOCITY := -320.0
const GRAVITY := 900.0
const CLIMB_SPEED := 100.0

enum State { IDLE, RUN, JUMP, FALL, CLIMB }

var ladders_in_range: Array[Area2D] = []
var state: State = State.IDLE


func _physics_process(delta: float) -> void:
	var horizontal_direction := Input.get_axis("ui_left", "ui_right")
	var vertical_direction := Input.get_axis("ui_up", "ui_down")

	if state == State.CLIMB:
		_handle_climb(delta, horizontal_direction, vertical_direction)
		return

	if not ladders_in_range.is_empty() and vertical_direction != 0.0:
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
	if ladders_in_range.is_empty():
		state = State.FALL
		velocity.y = 0.0
		return

	if Input.is_action_just_pressed("jump"):
		state = State.JUMP
		velocity.x = horizontal_direction * SPEED
		velocity.y = JUMP_VELOCITY
		move_and_slide()
		return

	var ladder := ladders_in_range[0]
	global_position.x = ladder.global_position.x
	velocity.x = 0.0
	velocity.y = vertical_direction * CLIMB_SPEED
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
