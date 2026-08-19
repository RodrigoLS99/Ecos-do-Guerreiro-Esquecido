extends CanvasLayer

@onready var heart_1: ColorRect = $MarginContainer/HBoxContainer/Hearts/Heart1
@onready var heart_2: ColorRect = $MarginContainer/HBoxContainer/Hearts/Heart2
@onready var heart_3: ColorRect = $MarginContainer/HBoxContainer/Hearts/Heart3
@onready var echo_icon: ColorRect = $MarginContainer/HBoxContainer/EchoContainer/EchoIcon

var player: Node2D = null


func _ready() -> void:
	player = get_tree().get_first_node_in_group(&"player")
	if player != null:
		if player.has_signal("health_changed"):
			player.health_changed.connect(_on_health_changed)
		if player.has_signal("echo_changed"):
			player.echo_changed.connect(_on_echo_changed)
		if "health" in player:
			_update_hearts(player.health)
		if "current_echo" in player:
			_update_echo(player.current_echo != null)
	else:
		_update_hearts(3)
		_update_echo(false)


func _on_health_changed(new_health: int) -> void:
	_update_hearts(new_health)


func _on_echo_changed(is_active: bool) -> void:
	_update_echo(is_active)


func _update_hearts(current_health: int) -> void:
	if heart_1:
		heart_1.visible = current_health >= 1
	if heart_2:
		heart_2.visible = current_health >= 2
	if heart_3:
		heart_3.visible = current_health >= 3


func _update_echo(is_active: bool) -> void:
	if echo_icon:
		echo_icon.modulate.a = 1.0 if is_active else 0.25
