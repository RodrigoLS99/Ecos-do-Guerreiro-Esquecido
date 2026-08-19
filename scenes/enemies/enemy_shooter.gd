extends StaticBody2D

@export var facing_direction := -1

var health := 2


func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		queue_free()
