extends CharacterBody2D

const SPEED := 160.0
const JUMP_VELOCITY := -320.0
const GRAVITY := 900.0
const CLIMB_SPEED := 100.0
const ATTACK_DURATION := 0.25
const ATTACK_HITBOX_WINDOW := 0.12
const MAX_HEALTH := 3
const INVINCIBILITY_TIME := 1.0
const HURT_DURATION := 0.15
const ECHO_SCENE := preload("res://scenes/player/echo.tscn")

enum State { IDLE, RUN, JUMP, FALL, CLIMB, ATTACK, HURT, DEAD }

signal health_changed(new_health: int)

var ladders_in_range: Array[Area2D] = []
var ladders_below_in_range: Array[Area2D] = []
var state: State = State.IDLE
var drop_through_remaining := 0.0
var current_echo: Node2D = null
var attack_in_progress := false
var health := MAX_HEALTH
var invincibility_remaining := 0.0
var hurt_remaining := 0.0


func _physics_process(delta: float) -> void:
	_update_drop_through(delta)
	_update_damage_timers(delta)
	if Input.is_action_just_pressed("echo_create"):
		create_echo()
	if Input.is_action_just_pressed("echo_collapse"):
		collapse_echo()

	var horizontal_direction := Input.get_axis("ui_left", "ui_right")
	var vertical_direction := Input.get_axis("ui_up", "ui_down")

	if state == State.HURT:
		_handle_hurt(delta)
		return

	if state == State.ATTACK:
		_handle_attack(delta)
		return

	if state == State.CLIMB:
		_handle_climb(delta, horizontal_direction, vertical_direction)
		return

	if Input.is_action_just_pressed("attack"):
		attack()
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


func _handle_attack(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	velocity.x = 0.0
	move_and_slide()


func _handle_hurt(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	velocity.x = 0.0
	move_and_slide()

	if hurt_remaining <= 0.0:
		_update_movement_state(0.0)


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


func _update_damage_timers(delta: float) -> void:
	if invincibility_remaining > 0.0:
		invincibility_remaining -= delta
		$Placeholder.modulate.a = 0.45 if invincibility_remaining > 0.0 else 1.0

	if hurt_remaining > 0.0:
		hurt_remaining -= delta


func create_echo() -> void:
	if current_echo != null and is_instance_valid(current_echo):
		current_echo.queue_free()

	current_echo = ECHO_SCENE.instantiate()
	current_echo.global_position = global_position
	get_tree().current_scene.add_child(current_echo)


func collapse_echo() -> void:
	if current_echo == null or not is_instance_valid(current_echo):
		current_echo = null
		return

	var target := current_echo.global_position
	current_echo.queue_free()
	current_echo = null
	global_position = target


func attack() -> void:
	if attack_in_progress:
		return

	attack_in_progress = true
	state = State.ATTACK
	velocity.x = 0.0
	$AttackHitbox/CollisionShape2D.set_deferred("disabled", false)

	await get_tree().create_timer(ATTACK_HITBOX_WINDOW).timeout
	$AttackHitbox/CollisionShape2D.set_deferred("disabled", true)
	await get_tree().create_timer(ATTACK_DURATION - ATTACK_HITBOX_WINDOW).timeout

	attack_in_progress = false
	_update_movement_state(0.0)


func _on_attack_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"enemy") and body.has_method("take_damage"):
		body.take_damage(1)


func _on_attack_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group(&"projectile") and area.has_method("destroy"):
		area.destroy()


func _on_hurtbox_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"enemy"):
		take_damage(1)
	elif body.is_in_group(&"hazard"):
		die_instant()


func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area.is_in_group(&"hazard") or area.is_in_group(&"pit"):
		die_instant()
		return

	if area.is_in_group(&"projectile"):
		if area.has_method("destroy"):
			area.destroy()
		take_damage(1)


func die_instant() -> void:
	if state == State.DEAD:
		return

	state = State.DEAD
	GameState.respawn_current_floor()


func take_damage(amount: int) -> void:
	if invincibility_remaining > 0.0 or state == State.DEAD:
		return

	health = max(health - amount, 0)
	health_changed.emit(health)
	invincibility_remaining = INVINCIBILITY_TIME
	hurt_remaining = HURT_DURATION
	state = State.HURT

	if health <= 0:
		die_instant()
