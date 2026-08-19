extends StaticBody2D

const PROJECTILE_SCENE := preload("res://scenes/combat/projectile.tscn")

@export var facing_direction := -1

var health := 2


func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		queue_free()


func _on_shoot_timer_timeout() -> void:
	var projectile := PROJECTILE_SCENE.instantiate()
	projectile.global_position = $ProjectileSpawn.global_position
	projectile.direction = facing_direction
	get_tree().current_scene.add_child(projectile)
