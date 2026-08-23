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

const COYOTE_TIME := 0.05
const JUMP_BUFFER_TIME := 0.08

enum State { IDLE, RUN, JUMP, FALL, CLIMB, ATTACK, HURT, DEAD }

signal health_changed(new_health: int)
signal echo_changed(is_active: bool)

var ladders_in_range: Array[Area2D] = []
var ladders_below_in_range: Array[Area2D] = []
var state: State = State.IDLE
var drop_through_remaining := 0.0
var current_echo: Node2D = null
var can_create_echo := true
var has_touched_ground_since_echo := true
var attack_in_progress := false
var facing_direction := 1
var health := MAX_HEALTH
var invincibility_remaining := 0.0
var hurt_remaining := 0.0
var step_timer := 0.0
var coyote_timer := 0.0
var jump_buffer_timer := 0.0

@onready var visual_root: Node2D = $Visual if has_node("Visual") else null
@onready var sprite_slot: Node2D = $Visual/SpriteSlot if has_node("Visual/SpriteSlot") else null
@onready var procedural_visual: Node2D = $Visual/Procedural if has_node("Visual/Procedural") else null


func _ready() -> void:
	_setup_visual_slots()
	var camera := get_node_or_null("Camera2D") as Camera2D
	if camera != null:
		camera.limit_left = 0
		camera.limit_top = 0
		camera.limit_bottom = 648
		var limit_marker := get_tree().current_scene.get_node_or_null("CameraLimitRight")
		if limit_marker != null:
			camera.limit_right = int(limit_marker.global_position.x)


func _setup_visual_slots() -> void:
	var has_sprite := false
	if sprite_slot != null:
		if sprite_slot is AnimatedSprite2D and (sprite_slot as AnimatedSprite2D).sprite_frames != null:
			has_sprite = true
		elif sprite_slot is Sprite2D and (sprite_slot as Sprite2D).texture != null:
			has_sprite = true

	if has_sprite:
		sprite_slot.visible = true
		if procedural_visual != null:
			procedural_visual.visible = false
	else:
		if sprite_slot != null:
			sprite_slot.visible = false
		if procedural_visual != null:
			procedural_visual.visible = true


func _update_animation() -> void:
	if sprite_slot == null or not (sprite_slot is AnimatedSprite2D):
		return
	var anim_sprite := sprite_slot as AnimatedSprite2D
	if anim_sprite.sprite_frames == null:
		return

	match state:
		State.IDLE:
			if anim_sprite.animation != &"idle":
				anim_sprite.play(&"idle")
		State.RUN:
			if anim_sprite.animation != &"run":
				anim_sprite.play(&"run")
		State.JUMP:
			if anim_sprite.animation != &"jump":
				anim_sprite.play(&"jump")
		State.FALL:
			if anim_sprite.animation != &"fall":
				anim_sprite.play(&"fall")
		State.CLIMB:
			if anim_sprite.animation != &"climb":
				anim_sprite.play(&"climb")
		State.ATTACK:
			anim_sprite.play(&"attack")
		State.HURT:
			anim_sprite.play(&"hurt")
		State.DEAD:
			anim_sprite.play(&"death")


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		if not is_on_floor():
			velocity.y += GRAVITY * delta
		velocity.x = 0.0
		move_and_slide()
		return

	if (global_position.y > 700.0 or global_position.y < -300.0) and state != State.DEAD:
		die_instant()
		return

	_update_drop_through(delta)
	_update_damage_timers(delta)
	_update_echo_recharge()

	# Atualização de Coyote Time e Jump Buffer calibrados com precisão
	if is_on_floor():
		coyote_timer = COYOTE_TIME
	else:
		coyote_timer -= delta
		if velocity.y < 0.0:
			coyote_timer = 0.0

	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER_TIME
	elif jump_buffer_timer > 0.0:
		jump_buffer_timer -= delta

	if Input.is_action_just_pressed("echo_create"):
		create_echo()
	if Input.is_action_just_pressed("echo_collapse"):
		collapse_echo()

	var horizontal_direction := Input.get_axis("ui_left", "ui_right")
	var vertical_direction := Input.get_axis("ui_up", "ui_down")

	if horizontal_direction != 0.0:
		facing_direction = int(sign(horizontal_direction))
		$AttackHitbox.position.x = 24.0 * facing_direction
		$AttackHitbox.scale.x = facing_direction
		if visual_root != null:
			visual_root.scale.x = facing_direction

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

	# Execução de Pulo Responsivo
	if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		velocity.y = JUMP_VELOCITY
		coyote_timer = 0.0
		jump_buffer_timer = 0.0
		if AudioManager:
			AudioManager.play_sfx("jump")

	# Pulo variável (cortar impulso vertical ao soltar o botão de pulo)
	if Input.is_action_just_released("jump") and velocity.y < -100.0:
		velocity.y = -100.0

	if not is_on_floor():
		velocity.y += GRAVITY * delta

	velocity.x = horizontal_direction * SPEED
	move_and_slide()
	_update_movement_state(horizontal_direction)
	_update_footsteps(delta, horizontal_direction)
	_update_echo_recharge()


func _update_footsteps(delta: float, horizontal_direction: float) -> void:
	if is_on_floor() and horizontal_direction != 0.0 and state == State.RUN:
		step_timer -= delta
		if step_timer <= 0.0:
			step_timer = 0.3
			if AudioManager:
				AudioManager.play_sfx("step", 0.35, randf_range(0.95, 1.05))
	else:
		step_timer = 0.12


func _handle_climb(_delta: float, horizontal_direction: float, vertical_direction: float) -> void:
	if ladders_in_range.is_empty() and ladders_below_in_range.is_empty():
		state = State.FALL
		velocity.y = 0.0
		return

	if Input.is_action_just_pressed("jump"):
		state = State.JUMP
		velocity.x = horizontal_direction * SPEED
		velocity.y = JUMP_VELOCITY
		coyote_timer = 0.0
		jump_buffer_timer = 0.0
		if AudioManager:
			AudioManager.play_sfx("jump")
		move_and_slide()
		return

	# Sair da escada andando para os lados
	if horizontal_direction != 0.0 and vertical_direction == 0.0:
		state = State.RUN if is_on_floor() else State.FALL
		velocity.x = horizontal_direction * SPEED
		velocity.y = 0.0
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
	_update_animation()


func _update_movement_state(horizontal_direction: float) -> void:
	if not is_on_floor():
		state = State.JUMP if velocity.y < 0.0 else State.FALL
	elif horizontal_direction != 0.0:
		state = State.RUN
	else:
		state = State.IDLE
	_update_animation()


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
		if visual_root != null:
			visual_root.modulate.a = 0.45 if invincibility_remaining > 0.0 else 1.0
		elif has_node("Placeholder"):
			$Placeholder.modulate.a = 0.45 if invincibility_remaining > 0.0 else 1.0
	else:
		if visual_root != null:
			visual_root.modulate.a = 1.0
		elif has_node("Placeholder"):
			$Placeholder.modulate.a = 1.0

	if hurt_remaining > 0.0:
		hurt_remaining -= delta


func _update_echo_recharge() -> void:
	if state == State.CLIMB:
		has_touched_ground_since_echo = true
		can_create_echo = true
		return

	if is_on_floor():
		if _is_standing_on_echo():
			can_create_echo = false
		else:
			has_touched_ground_since_echo = true
			can_create_echo = true
	else:
		can_create_echo = has_touched_ground_since_echo and (current_echo == null)


func _is_standing_on_echo() -> bool:
	if current_echo == null or not is_instance_valid(current_echo):
		return false

	var dx: float = abs(global_position.x - current_echo.global_position.x)
	var dy: float = global_position.y - (current_echo.global_position.y - 48.0)
	if dx <= 28.0 and abs(dy) <= 8.0:
		return true

	var floor_collider := $FloorDetector.get_collider() as Node
	if floor_collider != null:
		if floor_collider == current_echo or floor_collider.get_parent() == current_echo or floor_collider.is_in_group(&"echo"):
			return true

	for i in range(get_slide_collision_count()):
		var collision := get_slide_collision(i)
		var collider := collision.get_collider() as Node
		if collider != null:
			if collider == current_echo or collider.get_parent() == current_echo or collider.is_in_group(&"echo"):
				return true
	return false


func _spawn_magic_burst_fx(pos: Vector2, color: Color) -> void:
	var fx := Node2D.new()
	fx.global_position = pos
	fx.z_index = 6

	var ring := Polygon2D.new()
	ring.color = color
	ring.polygon = PackedVector2Array([
		Vector2(-16, 0), Vector2(-11, -11), Vector2(0, -16), Vector2(11, -11),
		Vector2(16, 0), Vector2(11, 11), Vector2(0, 16), Vector2(-11, 11)
	])
	fx.add_child(ring)

	var star := Polygon2D.new()
	star.color = Color(1.0, 1.0, 1.0, 0.9)
	star.polygon = PackedVector2Array([
		Vector2(0, -14), Vector2(4, -4), Vector2(14, 0), Vector2(4, 4),
		Vector2(0, 14), Vector2(-4, 4), Vector2(-14, 0), Vector2(-4, -4)
	])
	fx.add_child(star)

	get_tree().current_scene.add_child(fx)

	var tw := fx.create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(ring, "scale", Vector2(2.2, 2.2), 0.25)
	tw.tween_property(ring, "modulate:a", 0.0, 0.25)
	tw.tween_property(star, "scale", Vector2(1.8, 1.8), 0.22)
	tw.tween_property(star, "modulate:a", 0.0, 0.22)
	tw.chain().tween_callback(fx.queue_free)


func create_echo() -> void:
	if not can_create_echo or _is_standing_on_echo():
		return

	has_touched_ground_since_echo = false
	can_create_echo = false

	if current_echo != null and is_instance_valid(current_echo):
		current_echo.queue_free()

	current_echo = ECHO_SCENE.instantiate()
	current_echo.global_position = global_position
	get_tree().current_scene.add_child(current_echo)
	_spawn_magic_burst_fx(global_position, Color(0.25, 0.9, 0.95, 0.8))
	if AudioManager:
		AudioManager.play_sfx("echo_create")
	echo_changed.emit(true)


func collapse_echo() -> void:
	if current_echo == null or not is_instance_valid(current_echo):
		current_echo = null
		echo_changed.emit(false)
		return

	var origin := global_position
	var target := current_echo.global_position

	_spawn_magic_burst_fx(origin, Color(0.3, 0.75, 0.95, 0.75))
	_spawn_magic_burst_fx(target, Color(0.4, 0.98, 1.0, 0.9))

	current_echo.queue_free()
	current_echo = null
	global_position = target
	velocity = Vector2.ZERO
	can_create_echo = false
	has_touched_ground_since_echo = false
	if AudioManager:
		AudioManager.play_sfx("echo_teleport")
	echo_changed.emit(false)


func attack() -> void:
	if attack_in_progress:
		return

	attack_in_progress = true
	state = State.ATTACK
	velocity.x = 0.0
	_update_animation()
	if AudioManager:
		AudioManager.play_sfx("attack")
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
	if area.is_in_group(&"projectile"):
		if area.has_method("deflect"):
			area.deflect(facing_direction)
		elif area.has_method("destroy"):
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
		if area.get("is_deflected") == true:
			return
		if area.has_method("destroy"):
			area.destroy()
		take_damage(1)


func die_instant() -> void:
	if state == State.DEAD:
		return

	state = State.DEAD
	velocity = Vector2.ZERO
	_update_animation()
	if AudioManager:
		AudioManager.play_sfx("death")
	await get_tree().create_timer(0.5).timeout
	GameState.respawn_current_floor()


func take_damage(amount: int) -> void:
	if invincibility_remaining > 0.0 or state == State.DEAD:
		return

	health = max(health - amount, 0)
	health_changed.emit(health)
	invincibility_remaining = INVINCIBILITY_TIME
	hurt_remaining = HURT_DURATION
	state = State.HURT
	_update_animation()
	if AudioManager:
		AudioManager.play_sfx("hurt")

	if health <= 0:
		die_instant()
