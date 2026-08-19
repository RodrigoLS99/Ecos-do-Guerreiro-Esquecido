extends Area2D

const SPEED := 120.0
const LIFETIME := 6.0

var direction := -1


func _ready() -> void:
	get_tree().create_timer(LIFETIME).timeout.connect(destroy)


func _physics_process(delta: float) -> void:
	position.x += direction * SPEED * delta


func destroy() -> void:
	queue_free()
