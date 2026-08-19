extends CharacterBody2D

const SPEED := 160.0


func _physics_process(_delta: float) -> void:
	var direction := Input.get_axis("ui_left", "ui_right")
	velocity.x = direction * SPEED
	velocity.y = 0.0
	move_and_slide()
