extends Area2D

signal rescued

var is_rescued := false
var start_pos: Vector2
var time_passed := 0.0

@onready var crown: Polygon2D = $Visual/Crown if has_node("Visual/Crown") else null
@onready var aura: Polygon2D = $Visual/Aura if has_node("Visual/Aura") else null
@onready var heart_bubble: Node2D = $HeartBubble if has_node("HeartBubble") else null


func _ready() -> void:
	start_pos = position
	body_entered.connect(_on_body_entered)
	if heart_bubble:
		heart_bubble.visible = false


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
