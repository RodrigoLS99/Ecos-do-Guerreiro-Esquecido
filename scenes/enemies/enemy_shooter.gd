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
@onready var pip_1: Polygon2D = $HealthBar/Pip1 if has_node("HealthBar/Pip1") else null
@onready var pip_2: Polygon2D = $HealthBar/Pip2 if has_node("HealthBar/Pip2") else null


func _ready() -> void:
	health = max_health
	_update_facing(facing_direction)
	_update_health_display(false)


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
	_update_health_display(true)

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


func _update_health_display(animate: bool = true) -> void:
	_set_pip_state(pip_1, health >= 1, animate)
	_set_pip_state(pip_2, health >= 2, animate)


func _set_pip_state(pip: Polygon2D, is_active: bool, animate: bool) -> void:
	if pip == null:
		return
	if not animate:
		pip.visible = is_active
		pip.scale = Vector2.ONE
		pip.modulate.a = 1.0 if is_active else 0.0
		return

	if is_active:
		pip.visible = true
		pip.scale = Vector2.ONE
		pip.modulate.a = 1.0
	else:
		if pip.visible:
			var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.parallel().tween_property(pip, "scale", Vector2(1.5, 1.5), 0.18)
			tw.parallel().tween_property(pip, "modulate:a", 0.0, 0.18)
			tw.chain().tween_callback(func(): pip.visible = false)


func _on_shoot_timer_timeout() -> void:
	var projectile := PROJECTILE_SCENE.instantiate()
	projectile.global_position = $ProjectileSpawn.global_position
	projectile.direction = facing_direction
	get_tree().current_scene.add_child(projectile)
