extends StaticBody2D

@export var is_active_by_default := false
@export var target_offset := Vector2(0, 0)
@export var move_duration := 0.8
@export var fade_in_on_activate := false

@export var inactive_color := Color(0.22, 0.28, 0.36, 0.5)
@export var active_color := Color(0.35, 0.65, 0.85, 1.0)

var start_pos: Vector2
var is_active := false
var tween: Tween = null

@onready var collision_shape: CollisionShape2D = $CollisionShape2D if has_node("CollisionShape2D") else null
@onready var visual: Polygon2D = $Visual if has_node("Visual") else null


func _ready() -> void:
	start_pos = position
	if is_active_by_default:
		is_active = true
		position = start_pos + target_offset
		if collision_shape:
			collision_shape.set_deferred("disabled", false)
		if visual:
			visual.color = active_color
			visual.modulate.a = 1.0
	else:
		is_active = false
		if visual:
			visual.color = inactive_color
		if fade_in_on_activate:
			if collision_shape:
				collision_shape.set_deferred("disabled", true)
			if visual:
				visual.modulate.a = 0.0


func activate() -> void:
	open()


func open() -> void:
	if is_active:
		return
	is_active = true

	if tween and tween.is_valid():
		tween.kill()
	tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	if target_offset != Vector2.ZERO:
		tween.tween_property(self, "position", start_pos + target_offset, move_duration)

	if visual:
		tween.tween_property(visual, "color", active_color, move_duration)

	if fade_in_on_activate:
		if collision_shape:
			collision_shape.set_deferred("disabled", false)
		if visual:
			tween.tween_property(visual, "modulate:a", 1.0, move_duration)


func close() -> void:
	if not is_active:
		return
	is_active = false

	if tween and tween.is_valid():
		tween.kill()
	tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	if target_offset != Vector2.ZERO:
		tween.tween_property(self, "position", start_pos, move_duration)

	if visual:
		tween.tween_property(visual, "color", inactive_color, move_duration)

	if fade_in_on_activate:
		if visual:
			tween.tween_property(visual, "modulate:a", 0.0, move_duration)
		if collision_shape:
			collision_shape.set_deferred("disabled", true)
