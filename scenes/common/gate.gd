extends StaticBody2D

@export var is_closed_by_default := true
@export var closed_color := Color(0.95, 0.25, 0.25, 0.9)
@export var open_color := Color(0.25, 0.95, 0.45, 0.12)

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var visual: Polygon2D = $Visual


func _ready() -> void:
	if is_closed_by_default:
		close(true)
	else:
		open(true)


func open(instant := false) -> void:
	collision_shape.set_deferred("disabled", true)
	if visual:
		if instant:
			visual.color = open_color
		else:
			if AudioManager:
				AudioManager.play_sfx("gate_open")
			var tw := create_tween()
			tw.tween_property(visual, "color", open_color, 0.3)


func close(instant := false) -> void:
	collision_shape.set_deferred("disabled", false)
	if visual:
		if instant:
			visual.color = closed_color
		else:
			var tw := create_tween()
			tw.tween_property(visual, "color", closed_color, 0.3)
