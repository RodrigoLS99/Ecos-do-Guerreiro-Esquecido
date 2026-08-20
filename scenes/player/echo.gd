extends Node2D

var time_passed := 0.0

@onready var visual_root: Node2D = $Visual if has_node("Visual") else null
@onready var sprite_slot: Sprite2D = $Visual/SpriteSlot if has_node("Visual/SpriteSlot") else null
@onready var procedural_visual: Node2D = $Visual/Procedural if has_node("Visual/Procedural") else null
@onready var aura: Polygon2D = $Visual/Procedural/Aura if has_node("Visual/Procedural/Aura") else null


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


func _process(delta: float) -> void:
	time_passed += delta
	if aura != null:
		aura.scale = Vector2.ONE * (1.0 + sin(time_passed * 5.0) * 0.08)
		aura.modulate.a = 0.35 + sin(time_passed * 5.0) * 0.15
