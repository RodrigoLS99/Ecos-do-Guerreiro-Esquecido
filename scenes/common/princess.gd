extends Area2D

signal rescued

var is_rescued := false
var start_pos: Vector2
var time_passed := 0.0

@onready var sprite_slot: Sprite2D = $Visual/SpriteSlot if has_node("Visual/SpriteSlot") else null
@onready var procedural_visual: Node2D = $Visual/Procedural if has_node("Visual/Procedural") else null
@onready var crown: Polygon2D = $Visual/Procedural/Crown if has_node("Visual/Procedural/Crown") else null
@onready var aura: Polygon2D = $Visual/Procedural/Aura if has_node("Visual/Procedural/Aura") else null
@onready var heart_bubble: Node2D = $HeartBubble if has_node("HeartBubble") else null


func _ready() -> void:
	start_pos = position
	body_entered.connect(_on_body_entered)
	if heart_bubble:
		heart_bubble.visible = false
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
	# Gentle idle breathing
	$Visual.position.y = sin(time_passed * 2.5) * 2.0
	if aura and not is_rescued:
		aura.modulate.a = 0.4 + sin(time_passed * 3.0) * 0.2


func _on_body_entered(body: Node2D) -> void:
	if is_rescued:
		return
	if body.is_in_group(&"player"):
		is_rescued = true
		if AudioManager:
			AudioManager.play_sfx("princess_rescue")
		rescued.emit()
		
		# Delight animation / hearts
		if heart_bubble:
			heart_bubble.visible = true
			var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween.tween_property(heart_bubble, "position:y", -60.0, 0.8)
			tween.tween_property(heart_bubble, "modulate:a", 1.0, 0.4)
			tween.chain().tween_property(heart_bubble, "modulate:a", 0.0, 0.8)
		
		if aura:
			var tween_aura := create_tween()
			tween_aura.tween_property(aura, "modulate", Color(1.0, 0.85, 0.95, 0.8), 0.5)
