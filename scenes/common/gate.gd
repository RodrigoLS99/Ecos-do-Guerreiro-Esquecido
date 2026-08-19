extends StaticBody2D

@export var is_closed_by_default := true

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var visual: Polygon2D = $Visual


func _ready() -> void:
	if is_closed_by_default:
		close()
	else:
		open()


func open() -> void:
	collision_shape.set_deferred("disabled", true)
	visual.modulate.a = 0.15


func close() -> void:
	collision_shape.set_deferred("disabled", false)
	visual.modulate.a = 1.0
