extends StaticBody2D

const PROJECTILE_SCENE := preload("res://scenes/combat/projectile.tscn")

@export var facing_direction := -1
@export var auto_face_player := true
@export var max_health := 2
@export var defeat_target: NodePath

signal defeated

var health := 2
var flash_timer := 0.0
var is_dying := false

@onready var visuals: Node2D = $Visuals if has_node("Visuals") else null
@onready var sprite_slot: Node = $Visuals/SpriteSlot if has_node("Visuals/SpriteSlot") else null
@onready var procedural_visual: Node2D = $Visuals/Procedural if has_node("Visuals/Procedural") else null
@onready var health_bar: Node2D = $HealthBar if has_node("HealthBar") else null
@onready var pip_1: Polygon2D = $HealthBar/Pip1 if has_node("HealthBar/Pip1") else null
@onready var pip_2: Polygon2D = $HealthBar/Pip2 if has_node("HealthBar/Pip2") else null
@onready var shoot_timer: Timer = $ShootTimer if has_node("ShootTimer") else null


func _ready() -> void:
	_setup_visual_slots()
	health = max_health
	_update_facing(facing_direction)
	_update_health_display(false)


func _setup_visual_slots() -> void:
	if sprite_slot != null:
		if sprite_slot is AnimatedSprite2D and sprite_slot.sprite_frames != null:
			sprite_slot.visible = true
			sprite_slot.play(&"idle")
			if procedural_visual != null:
				procedural_visual.visible = false
		elif sprite_slot is Sprite2D and sprite_slot.texture != null:
			sprite_slot.visible = true
			if procedural_visual != null:
				procedural_visual.visible = false
		else:
			sprite_slot.visible = false
			if procedural_visual != null:
				procedural_visual.visible = true
	else:
		if procedural_visual != null:
			procedural_visual.visible = true


func _physics_process(delta: float) -> void:
	if is_dying:
		return

	if auto_face_player:
		var player := get_tree().get_first_node_in_group(&"player") as Node2D
		if player != null and is_instance_valid(player):
			var target_dir := -1 if player.global_position.x < global_position.x else 1
			if target_dir != facing_direction:
				_update_facing(target_dir)

	if flash_timer > 0.0:
		flash_timer -= delta
		if flash_timer <= 0.0 and visuals != null:
			visuals.modulate = Color.WHITE


func _update_facing(new_dir: int) -> void:
	facing_direction = new_dir
	if has_node("ProjectileSpawn"):
		$ProjectileSpawn.position.x = -24.0 if facing_direction == -1 else 24.0
	if visuals != null:
		# Sprite is natively drawn facing RIGHT
		visuals.scale.x = 1.0 if facing_direction == 1 else -1.0


func take_damage(amount: int) -> void:
	if is_dying:
		return

	health -= amount
	_update_health_display(true)
	if AudioManager:
		AudioManager.play_sfx("hit_enemy")

	flash_timer = 0.12
	if visuals != null:
		visuals.modulate = Color(2.5, 0.4, 0.4, 1.0)

	if health <= 0:
		is_dying = true
		if shoot_timer != null:
			shoot_timer.stop()
		defeated.emit()
		if not defeat_target.is_empty():
			var target := get_node_or_null(defeat_target)
			if target != null:
				if target.has_method("activate"):
					target.activate()
				elif target.has_method("open"):
					target.open()

		if sprite_slot is AnimatedSprite2D and sprite_slot.sprite_frames != null and sprite_slot.sprite_frames.has_animation(&"defeat"):
			sprite_slot.play(&"defeat")
			var tw := create_tween()
			tw.tween_interval(0.6)
			tw.tween_property(self, "modulate:a", 0.0, 0.25)
			tw.tween_callback(queue_free)
		else:
			queue_free()
	else:
		if sprite_slot is AnimatedSprite2D and sprite_slot.sprite_frames != null and sprite_slot.sprite_frames.has_animation(&"hurt"):
			sprite_slot.play(&"hurt")
			var tw := create_tween()
			tw.tween_interval(0.35)
			tw.tween_callback(func():
				if not is_dying and sprite_slot != null and is_instance_valid(sprite_slot):
					sprite_slot.play(&"idle")
			)


func _update_health_display(animate: bool = true) -> void:
	_set_pip_state(pip_1, health >= 1, animate)
	_set_pip_state(pip_2, health >= 2, animate)


func _set_pip_state(pip: Polygon2D, is_active: bool, animate: bool) -> void:
	if pip == null:
		return
	if not animate:
		pip.visible = is_active
		pip.scale = Vector2.ONE
		pip.modulate.a = 1.0 if is_active else 0.0
		return

	if is_active:
		pip.visible = true
		pip.scale = Vector2.ONE
		pip.modulate.a = 1.0
	else:
		if pip.visible:
			var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.parallel().tween_property(pip, "scale", Vector2(1.5, 1.5), 0.18)
			tw.parallel().tween_property(pip, "modulate:a", 0.0, 0.18)
			tw.chain().tween_callback(func(): pip.visible = false)


func _on_shoot_timer_timeout() -> void:
	if is_dying:
		return

	if sprite_slot is AnimatedSprite2D and sprite_slot.sprite_frames != null and sprite_slot.sprite_frames.has_animation(&"shoot"):
		sprite_slot.play(&"shoot")
		var tw := create_tween()
		tw.tween_interval(0.25)
		tw.tween_callback(_spawn_projectile)
		tw.tween_interval(0.25)
		tw.tween_callback(func():
			if not is_dying and sprite_slot != null and is_instance_valid(sprite_slot):
				sprite_slot.play(&"idle")
		)
	else:
		_spawn_projectile()


func _spawn_projectile() -> void:
	if is_dying:
		return
	var projectile := PROJECTILE_SCENE.instantiate()
	var spawn_pos := global_position + Vector2(-24.0 if facing_direction == -1 else 24.0, 0.0)
	if has_node("ProjectileSpawn"):
		spawn_pos = $ProjectileSpawn.global_position
	projectile.global_position = spawn_pos
	projectile.direction = facing_direction
	if AudioManager:
		AudioManager.play_sfx("projectile_shoot")
	get_tree().current_scene.add_child(projectile)
