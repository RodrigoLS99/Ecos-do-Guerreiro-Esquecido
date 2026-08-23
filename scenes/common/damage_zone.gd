extends Area2D

@export var damage_interval := 1.2
@export var is_active_by_default := false

var active := false
var timer := 0.0
var overlapping_player: Node2D = null

@onready var visual: Polygon2D = $Visual if has_node("Visual") else null


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if is_active_by_default:
		activate()
	else:
		deactivate()


func activate() -> void:
	active = true
	timer = damage_interval
	if visual != null:
		visual.visible = true


func deactivate() -> void:
	active = false
	if visual != null:
		visual.visible = false


func _physics_process(delta: float) -> void:
	if not active or overlapping_player == null:
		return

	timer -= delta
	if timer <= 0.0:
		timer = damage_interval
		if is_instance_valid(overlapping_player) and overlapping_player.has_method("take_damage"):
			overlapping_player.take_damage(1)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		overlapping_player = body


func _on_body_exited(body: Node2D) -> void:
	if body == overlapping_player:
		overlapping_player = null
