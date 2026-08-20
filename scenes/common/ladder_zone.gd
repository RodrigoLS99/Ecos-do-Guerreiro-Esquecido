extends Area2D

@onready var sprite_slot: Sprite2D = $Visual/SpriteSlot if has_node("Visual/SpriteSlot") else null
@onready var procedural_visual: Node2D = $Visual/Procedural if has_node("Visual/Procedural") else null


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
