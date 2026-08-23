extends Area2D

@export var speed := 180.0
@export var direction := -1

var is_deflected := false
var lifetime := 2.8

@onready var visuals: Node2D = $Visuals if has_node("Visuals") else null
@onready var sprite_slot: Node = $Visuals/SpriteSlot if has_node("Visuals/SpriteSlot") else null
@onready var procedural_visual: Node2D = $Visuals/Procedural if has_node("Visuals/Procedural") else null


func _ready() -> void:
	_setup_visuals()
	_update_direction()


func _setup_visuals() -> void:
	if sprite_slot != null:
		if sprite_slot is AnimatedSprite2D and sprite_slot.sprite_frames != null:
			sprite_slot.visible = true
			sprite_slot.play(&"normal")
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


func _update_direction() -> void:
	if visuals != null:
		# Arrowhead is on the RIGHT side of the sprite texture
		visuals.scale.x = 1.0 if direction == 1 else -1.0


func _physics_process(delta: float) -> void:
	global_position.x += direction * speed * delta

	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()


func deflect(new_direction: int) -> void:
	if is_deflected:
		return
	is_deflected = true
	direction = new_direction
	speed *= 1.4
	lifetime = 2.8
	_update_direction()

	if sprite_slot is AnimatedSprite2D and sprite_slot.sprite_frames != null and sprite_slot.sprite_frames.has_animation(&"deflected"):
		sprite_slot.play(&"deflected")

	if AudioManager:
		AudioManager.play_sfx("projectile_parry")


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"player") and not is_deflected:
		if body.has_method("take_damage"):
			body.take_damage(1)
		queue_free()
	elif body.is_in_group(&"enemy") and is_deflected:
		if body.has_method("take_damage"):
			body.take_damage(1)
		queue_free()
	elif not body.is_in_group(&"player") and not body.is_in_group(&"enemy") and not body.is_in_group(&"echo"):
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	# Only deflected arrows have the power to cancel out other arrows
	if area.is_in_group(&"projectile"):
		if is_deflected or area.get("is_deflected") == true:
			if AudioManager:
				AudioManager.play_sfx("projectile_parry")
			area.queue_free()
			queue_free()
			return

	# Check parry with player sword attack
	if not is_deflected and (area.name == "AttackHitbox" or area.is_in_group(&"player_attack")):
		var parent := area.get_parent()
		var player_facing := 1
		if parent != null and "facing_direction" in parent:
			player_facing = parent.facing_direction
		deflect(player_facing)
