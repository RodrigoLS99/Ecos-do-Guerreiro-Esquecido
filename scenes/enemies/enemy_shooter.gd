extends StaticBody2D

const PROJECTILE_SCENE := preload("res://scenes/combat/projectile.tscn")

@export var facing_direction := -1
@export var auto_face_player := true
@export var max_health := 2
@export var defeat_target: NodePath

signal defeated

var health := 2
var flash_timer := 0.0

@onready var visuals: Node2D = $Visuals if has_node("Visuals") else null
@onready var health_bar: Node2D = $HealthBar if has_node("HealthBar") else null


func _ready() -> void:
	health = max_health
	_update_facing(facing_direction)
	_update_health_display()


func _physics_process(delta: float) -> void:
	if auto_face_player:
		var player := get_tree().get_first_node_in_group(&"player") as Node2D
		if player != null and is_instance_valid(player):
			var target_dir := -1 if player.global_position.x < global_position.x else 1
			if target_dir != facing_direction:
				_update_facing(target_dir)

	if flash_timer > 0.0:
		flash_timer -= delta
		if flash_timer <= 0.0 and visuals != null:
			visuals.modulate = Color.WHITE


func _update_facing(new_dir: int) -> void:
	facing_direction = new_dir
	if has_node("ProjectileSpawn"):
		$ProjectileSpawn.position.x = 24.0 * facing_direction
	if visuals != null:
		visuals.scale.x = 1.0 if facing_direction == -1 else -1.0


func take_damage(amount: int) -> void:
	health -= amount
	_update_health_display()

	flash_timer = 0.12
	if visuals != null:
		visuals.modulate = Color(2.5, 0.4, 0.4, 1.0)

	if health <= 0:
		defeated.emit()
		if not defeat_target.is_empty():
			var target := get_node_or_null(defeat_target)
			if target != null:
				if target.has_method("activate"):
					target.activate()
				elif target.has_method("open"):
					target.open()
		queue_free()


func _update_health_display() -> void:
	if health_bar == null:
		return
	if health_bar.has_node("Heart1"):
		health_bar.get_node("Heart1").visible = health >= 1
	if health_bar.has_node("Heart2"):
		health_bar.get_node("Heart2").visible = health >= 2


func _on_shoot_timer_timeout() -> void:
	var projectile := PROJECTILE_SCENE.instantiate()
	projectile.global_position = $ProjectileSpawn.global_position
	projectile.direction = facing_direction
	get_tree().current_scene.add_child(projectile)
