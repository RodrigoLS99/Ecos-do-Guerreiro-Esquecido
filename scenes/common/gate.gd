extends StaticBody2D

const COLOR_RUNE_LOCKED := Color(0.75, 0.25, 0.85, 0.9)
const COLOR_RUNE_UNLOCKED := Color(0.25, 0.92, 0.95, 0.95)

@export var is_closed_by_default := true

var is_open_state := false
var time_passed := 0.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D if has_node("CollisionShape2D") else null
@onready var closed_barrier: Node2D = $Visual/ClosedBarrier if has_node("Visual/ClosedBarrier") else null
@onready var open_passage: Node2D = $Visual/OpenPassage if has_node("Visual/OpenPassage") else null
@onready var mystic_aura: Polygon2D = $Visual/ClosedBarrier/MysticAura if has_node("Visual/ClosedBarrier/MysticAura") else null
@onready var astral_veil: Polygon2D = $Visual/ClosedBarrier/AstralVeil if has_node("Visual/ClosedBarrier/AstralVeil") else null
@onready var arcane_seal: Node2D = $Visual/ClosedBarrier/ArcaneSeal if has_node("Visual/ClosedBarrier/ArcaneSeal") else null
@onready var g1: Node2D = $Visual/ClosedBarrier/RuneGlyph1 if has_node("Visual/ClosedBarrier/RuneGlyph1") else null
@onready var g2: Node2D = $Visual/ClosedBarrier/RuneGlyph2 if has_node("Visual/ClosedBarrier/RuneGlyph2") else null
@onready var g3: Node2D = $Visual/ClosedBarrier/RuneGlyph3 if has_node("Visual/ClosedBarrier/RuneGlyph3") else null
@onready var g4: Node2D = $Visual/ClosedBarrier/RuneGlyph4 if has_node("Visual/ClosedBarrier/RuneGlyph4") else null
@onready var runes_left: Node2D = $Visual/StoneFrame/PillarRunesLeft if has_node("Visual/StoneFrame/PillarRunesLeft") else null
@onready var runes_right: Node2D = $Visual/StoneFrame/PillarRunesRight if has_node("Visual/StoneFrame/PillarRunesRight") else null


func _ready() -> void:
	if is_closed_by_default:
		close(true)
	else:
		open(true)


func _process(delta: float) -> void:
	time_passed += delta

	if not is_open_state:
		# Mystical astral breathing
		if mystic_aura != null:
			mystic_aura.modulate.a = 0.5 + sin(time_passed * 3.0) * 0.3
		if astral_veil != null:
			astral_veil.scale.x = 1.0 + sin(time_passed * 4.0) * 0.15
			astral_veil.modulate.a = 0.6 + cos(time_passed * 3.5) * 0.25

		if arcane_seal != null:
			arcane_seal.position.y = sin(time_passed * 2.0) * 2.5
			arcane_seal.rotation = sin(time_passed * 1.5) * 0.1
			arcane_seal.scale = Vector2.ONE * (1.0 + cos(time_passed * 2.5) * 0.08)

		# Levitate runic glyphs
		if g1 != null:
			g1.position.y = -30.0 + sin(time_passed * 2.2 + 0.5) * 1.5
		if g2 != null:
			g2.position.y = -15.0 + sin(time_passed * 2.2 + 1.2) * 1.5
		if g3 != null:
			g3.position.y = 15.0 + sin(time_passed * 2.2 + 2.0) * 1.5
		if g4 != null:
			g4.position.y = 30.0 + sin(time_passed * 2.2 + 2.8) * 1.5


func _set_runes_color(target_color: Color) -> void:
	for rune_group in [runes_left, runes_right]:
		if rune_group != null:
			for child in rune_group.get_children():
				if child is Polygon2D:
					child.color = target_color


func open(instant := false) -> void:
	is_open_state = true
	if collision_shape != null:
		collision_shape.set_deferred("disabled", true)

	if instant:
		_set_runes_color(COLOR_RUNE_UNLOCKED)
		if closed_barrier != null:
			closed_barrier.visible = false
			closed_barrier.modulate.a = 0.0
		if open_passage != null:
			open_passage.visible = true
			open_passage.modulate.a = 1.0
	else:
		if AudioManager:
			AudioManager.play_sfx("gate_open")

		_set_runes_color(COLOR_RUNE_UNLOCKED)

		if closed_barrier != null:
			var tw_close := create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw_close.tween_property(closed_barrier, "modulate:a", 0.0, 0.4)
			tw_close.tween_property(closed_barrier, "scale:x", 0.1, 0.4)
			tw_close.chain().tween_callback(func(): closed_barrier.visible = false)

		if open_passage != null:
			open_passage.visible = true
			open_passage.modulate.a = 0.0
			var tw_open := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw_open.tween_interval(0.15)
			tw_open.tween_property(open_passage, "modulate:a", 1.0, 0.35)


func close(instant := false) -> void:
	is_open_state = false
	if collision_shape != null:
		collision_shape.set_deferred("disabled", false)

	if instant:
		_set_runes_color(COLOR_RUNE_LOCKED)
		if open_passage != null:
			open_passage.visible = false
			open_passage.modulate.a = 0.0
		if closed_barrier != null:
			closed_barrier.visible = true
			closed_barrier.modulate.a = 1.0
			closed_barrier.scale = Vector2.ONE
	else:
		_set_runes_color(COLOR_RUNE_LOCKED)

		if open_passage != null:
			var tw_open := create_tween()
			tw_open.tween_property(open_passage, "modulate:a", 0.0, 0.25)
			tw_open.tween_callback(func(): open_passage.visible = false)

		if closed_barrier != null:
			closed_barrier.visible = true
			closed_barrier.modulate.a = 0.0
			closed_barrier.scale = Vector2(0.1, 1.0)
			var tw_close := create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw_close.tween_property(closed_barrier, "modulate:a", 1.0, 0.35)
			tw_close.tween_property(closed_barrier, "scale:x", 1.0, 0.35)
