extends Area2D

signal collected

@export var artifact_name := "Artefato Sagrado"

var is_collected := false
var start_y := 0.0
var time_passed := 0.0

@onready var visual: Node2D = $Visual if has_node("Visual") else null
@onready var aura: Polygon2D = $Visual/Aura if has_node("Visual/Aura") else null


func _ready() -> void:
	start_y = position.y
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if is_collected:
		return
	time_passed += delta
	# Gentle floating bobbing
	position.y = start_y + sin(time_passed * 3.0) * 6.0
	if aura:
		aura.scale = Vector2.ONE * (1.0 + sin(time_passed * 4.0) * 0.15)
		aura.modulate.a = 0.5 + sin(time_passed * 4.0) * 0.25


func _on_body_entered(body: Node2D) -> void:
	if is_collected:
		return
	if body.is_in_group(&"player"):
		is_collected = true
		collected.emit()
		
		# Collection animation
		var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "position:y", position.y - 40.0, 0.6)
		tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.6)
		tween.tween_property(self, "modulate:a", 0.0, 0.6)
		tween.chain().tween_callback(queue_free)
