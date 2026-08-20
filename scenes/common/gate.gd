extends StaticBody2D

@export var is_closed_by_default := true
@export var closed_color := Color(0.95, 0.25, 0.25, 0.9)
@export var open_color := Color(0.25, 0.95, 0.45, 0.12)

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var sprite_slot: Sprite2D = $Visual/SpriteSlot if has_node("Visual/SpriteSlot") else null
@onready var procedural_visual: Polygon2D = $Visual/Procedural if has_node("Visual/Procedural") else ($Visual as Polygon2D if has_node("Visual") else null)


func _ready() -> void:
	if sprite_slot != null and sprite_slot.texture != null:
		sprite_slot.visible = true
		if procedural_visual != null:
			procedural_visual.visible = false
	else:
		if sprite_slot != null:
			sprite_slot.visible = false
		if procedural_visual != null:
			procedural_visual.visible = true

	if is_closed_by_default:
		close(true)
	else:
		open(true)


func open(instant := false) -> void:
	collision_shape.set_deferred("disabled", true)
	if procedural_visual != null:
		if instant:
			procedural_visual.color = open_color
		else:
			if AudioManager:
				AudioManager.play_sfx("gate_open")
			var tw := create_tween()
			tw.tween_property(procedural_visual, "color", open_color, 0.3)
	elif sprite_slot != null:
		if instant:
			sprite_slot.modulate.a = 0.2
		else:
			if AudioManager:
				AudioManager.play_sfx("gate_open")
			var tw := create_tween()
			tw.tween_property(sprite_slot, "modulate:a", 0.2, 0.3)


func close(instant := false) -> void:
	collision_shape.set_deferred("disabled", false)
	if procedural_visual != null:
		if instant:
			procedural_visual.color = closed_color
		else:
			var tw := create_tween()
			tw.tween_property(procedural_visual, "color", closed_color, 0.3)
	elif sprite_slot != null:
		if instant:
			sprite_slot.modulate.a = 1.0
		else:
			var tw := create_tween()
			tw.tween_property(sprite_slot, "modulate:a", 1.0, 0.3)
