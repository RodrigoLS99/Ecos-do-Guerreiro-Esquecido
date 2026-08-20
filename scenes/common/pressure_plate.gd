extends Area2D

@export var open_target: NodePath
@export var close_target: NodePath
@export var trigger_target: NodePath

var is_pressed := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"player") and not is_pressed:
		is_pressed = true
		if AudioManager:
			AudioManager.play_sfx("plate_pressed")
		$Visual.color = Color(0.2, 0.9, 0.5, 1.0)
		if not open_target.is_empty():
			var gate_to_open = get_node_or_null(open_target)
			if gate_to_open and gate_to_open.has_method("open"):
				gate_to_open.open()
		if not close_target.is_empty():
			var gate_to_close = get_node_or_null(close_target)
			if gate_to_close and gate_to_close.has_method("close"):
				gate_to_close.close()
		if not trigger_target.is_empty():
			var target_node = get_node_or_null(trigger_target)
			if target_node and target_node.has_method("activate"):
				target_node.activate()
