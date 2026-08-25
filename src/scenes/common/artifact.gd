extends Area2D

signal collected

@export var artifact_name := "Artefato Sagrado"

var is_collected := false
var start_y := 0.0
var time_passed := 0.0

@onready var visual: Node2D = $Visual if has_node("Visual") else null
@onready var aura: Polygon2D = $Visual/Aura if has_node("Visual/Aura") else null
@onready var aura_inner: Polygon2D = $Visual/AuraInner if has_node("Visual/AuraInner") else null
@onready var sprite_slot: Sprite2D = $Visual/SpriteSlot if has_node("Visual/SpriteSlot") else null
@onready var procedural_visual: Node2D = $Visual/Procedural if has_node("Visual/Procedural") else null


func _ready() -> void:
	start_y = position.y
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
	if is_collected:
		return
	time_passed += delta
	# Gentle floating bobbing
	position.y = start_y + sin(time_passed * 3.0) * 5.0

	# Pulse glowing aura
	if aura != null:
		aura.scale = Vector2.ONE * (1.0 + sin(time_passed * 4.0) * 0.12)
		aura.modulate.a = 0.5 + sin(time_passed * 4.0) * 0.25
	if aura_inner != null:
		aura_inner.scale = Vector2.ONE * (1.0 + cos(time_passed * 4.0) * 0.08)
		aura_inner.modulate.a = 0.6 + cos(time_passed * 4.0) * 0.2


func _on_body_entered(body: Node2D) -> void:
	if is_collected:
		return
	if body.is_in_group(&"player"):
		is_collected = true
		if AudioManager:
			AudioManager.play_sfx("artifact_collect")
		collected.emit()

		# Collection animation
		var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "position:y", position.y - 30.0, 0.5)
		tween.tween_property(self, "scale", Vector2(1.4, 1.4), 0.5)
		tween.tween_property(self, "modulate:a", 0.0, 0.5)
		tween.chain().tween_callback(queue_free)
