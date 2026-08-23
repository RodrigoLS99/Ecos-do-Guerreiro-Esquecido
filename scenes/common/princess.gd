extends Area2D

signal rescued

var is_rescued := false
var time_passed := 0.0

@onready var visual: Node2D = $Visual if has_node("Visual") else null
@onready var sprite_slot: Node = $Visual/SpriteSlot if has_node("Visual/SpriteSlot") else null
@onready var procedural_visual: Node2D = $Visual/Procedural if has_node("Visual/Procedural") else null
@onready var aura: Polygon2D = $Visual/Procedural/Aura if has_node("Visual/Procedural/Aura") else null
@onready var heart_bubble: Node2D = $HeartBubble if has_node("HeartBubble") else null


func _ready() -> void:
	if heart_bubble != null:
		heart_bubble.visible = false
	_setup_visual_slots()


func _setup_visual_slots() -> void:
	if sprite_slot != null:
		if sprite_slot is AnimatedSprite2D and sprite_slot.sprite_frames != null:
			sprite_slot.visible = true
			sprite_slot.play(&"captured")
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


func _process(delta: float) -> void:
	time_passed += delta
	if visual != null and not is_rescued:
		visual.position.y = sin(time_passed * 2.5) * 1.5
	if aura != null and not is_rescued:
		aura.modulate.a = 0.4 + sin(time_passed * 3.0) * 0.2


func _on_body_entered(body: Node2D) -> void:
	if is_rescued:
		return

	if body.is_in_group(&"player"):
		is_rescued = true
		if AudioManager:
			AudioManager.play_sfx("princess_rescue")
		rescued.emit()

		if visual != null:
			visual.position.y = 0.0

		if sprite_slot is AnimatedSprite2D and sprite_slot.sprite_frames != null and sprite_slot.sprite_frames.has_animation(&"rescued"):
			sprite_slot.play(&"rescued")

		# Float heart animation
		if heart_bubble != null:
			heart_bubble.visible = true
			heart_bubble.position = Vector2(0, -40.0)
			heart_bubble.modulate.a = 0.0
			var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.tween_property(heart_bubble, "position:y", -65.0, 0.8)
			tw.tween_property(heart_bubble, "modulate:a", 1.0, 0.3)
			tw.chain().tween_property(heart_bubble, "modulate:a", 0.0, 0.5)
