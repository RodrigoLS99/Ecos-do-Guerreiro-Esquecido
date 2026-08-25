extends Area2D

const COLOR_RUNE_UNPRESSED := Color(1.0, 0.82, 0.35, 0.95)
const COLOR_RUNE_PRESSED := Color(0.25, 0.95, 0.85, 1.0)
const COLOR_AURA_UNPRESSED := Color(0.75, 0.25, 0.85, 0.3)
const COLOR_AURA_PRESSED := Color(0.25, 0.95, 0.85, 0.6)

@export var open_target: NodePath
@export var close_target: NodePath
@export var trigger_target: NodePath

var is_pressed := false
var time_passed := 0.0

@onready var moving_plate: Node2D = $Visual/MovingPlate if has_node("Visual/MovingPlate") else null
@onready var rune_glyph: Polygon2D = $Visual/MovingPlate/RuneGlyph if has_node("Visual/MovingPlate/RuneGlyph") else null
@onready var rune_aura: Polygon2D = $Visual/MovingPlate/RuneGlowAura if has_node("Visual/MovingPlate/RuneGlowAura") else null


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	if not is_pressed:
		time_passed += delta
		if rune_aura != null:
			rune_aura.modulate.a = 0.6 + sin(time_passed * 3.0) * 0.3


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"player") and not is_pressed:
		is_pressed = true
		if AudioManager:
			AudioManager.play_sfx("plate_pressed")

		# Press down animation
		if moving_plate != null:
			var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.tween_property(moving_plate, "position:y", 4.0, 0.1)

		if rune_glyph != null:
			rune_glyph.color = COLOR_RUNE_PRESSED
		if rune_aura != null:
			rune_aura.color = COLOR_AURA_PRESSED

		if not open_target.is_empty():
			var gate_to_open = get_node_or_null(open_target)
			if gate_to_open and gate_to_open.has_method("open"):
				gate_to_open.open()

		if not close_target.is_empty():
			var gate_to_close = get_node_or_null(close_target)
			if gate_to_close and gate_to_close.has_method("close"):
				gate_to_close.close()

		if not trigger_target.is_empty():
			var target_node = get_node_or_null(trigger_target)
			if target_node and target_node.has_method("activate"):
				target_node.activate()
