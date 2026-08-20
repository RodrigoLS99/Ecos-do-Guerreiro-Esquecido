extends Area2D

const SPEED := 140.0
const DEFLECTED_SPEED := 200.0
const LIFETIME := 6.0

var direction := -1
var is_deflected := false


func _ready() -> void:
	get_tree().create_timer(LIFETIME).timeout.connect(destroy)
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	var current_speed := DEFLECTED_SPEED if is_deflected else SPEED
	position.x += direction * current_speed * delta


func deflect(new_direction: int) -> void:
	is_deflected = true
	direction = new_direction
	if AudioManager:
		AudioManager.play_sfx("projectile_deflect")
	if has_node("Placeholder"):
		$Placeholder.color = Color(0.2, 0.9, 1.0, 1.0)


func _on_body_entered(body: Node2D) -> void:
	if is_deflected and body.is_in_group(&"enemy"):
		if body.has_method("take_damage"):
			body.take_damage(1)
		destroy()


func _on_area_entered(area: Area2D) -> void:
	if is_deflected and area.is_in_group(&"projectile") and area != self:
		if not area.get("is_deflected"):
			if area.has_method("destroy"):
				area.destroy()
			destroy()


func destroy() -> void:
	queue_free()
