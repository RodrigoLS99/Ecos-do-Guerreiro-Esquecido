extends CanvasLayer

@onready var heart_fill_1: Node2D = %HeartFill1 if has_node("%HeartFill1") else null
@onready var heart_fill_2: Node2D = %HeartFill2 if has_node("%HeartFill2") else null
@onready var heart_fill_3: Node2D = %HeartFill3 if has_node("%HeartFill3") else null
@onready var echo_gem_active: Node2D = %EchoGemActive if has_node("%EchoGemActive") else null
@onready var echo_status_label: Label = %EchoStatusLabel if has_node("%EchoStatusLabel") else null

var player: Node2D = null
var current_displayed_health := 3
var time_passed := 0.0


func _ready() -> void:
	player = get_tree().get_first_node_in_group(&"player")
	if player != null:
		if player.has_signal("health_changed"):
			player.health_changed.connect(_on_health_changed)
		if player.has_signal("echo_changed"):
			player.echo_changed.connect(_on_echo_changed)
		if "health" in player:
			_update_hearts(player.health, false)
		if "current_echo" in player:
			_update_echo(player.current_echo != null)
	else:
		_update_hearts(3, false)
		_update_echo(false)


func _process(delta: float) -> void:
	time_passed += delta
	if echo_gem_active != null and echo_gem_active.visible:
		# Spectral breathing pulse for active echo gem
		var s = 1.0 + sin(time_passed * 3.5) * 0.08
		echo_gem_active.scale = Vector2(s, s)


func _on_health_changed(new_health: int) -> void:
	_update_hearts(new_health, true)


func _on_echo_changed(is_active: bool) -> void:
	_update_echo(is_active)


func _update_hearts(target_health: int, animate: bool = true) -> void:
	_set_heart_state(heart_fill_1, target_health >= 1, animate)
	_set_heart_state(heart_fill_2, target_health >= 2, animate)
	_set_heart_state(heart_fill_3, target_health >= 3, animate)
	current_displayed_health = target_health


func _set_heart_state(heart_fill: Node2D, is_full: bool, animate: bool) -> void:
	if heart_fill == null:
		return

	if not animate:
		heart_fill.visible = is_full
		heart_fill.scale = Vector2.ONE
		heart_fill.modulate.a = 1.0 if is_full else 0.0
		return

	if is_full:
		if not heart_fill.visible or heart_fill.modulate.a < 0.9:
			var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			heart_fill.visible = true
			heart_fill.scale = Vector2(0.3, 0.3)
			heart_fill.modulate.a = 0.0
			tw.parallel().tween_property(heart_fill, "scale", Vector2.ONE, 0.3)
			tw.parallel().tween_property(heart_fill, "modulate:a", 1.0, 0.2)
	else:
		if heart_fill.visible:
			var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.parallel().tween_property(heart_fill, "scale", Vector2(1.4, 1.4), 0.25)
			tw.parallel().tween_property(heart_fill, "modulate:a", 0.0, 0.25)
			tw.chain().tween_callback(func(): heart_fill.visible = false)


func _update_echo(is_placed: bool) -> void:
	if echo_gem_active:
		if is_placed:
			# Eco ativo no mundo (aceso e radiante)
			echo_gem_active.visible = true
			var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.tween_property(echo_gem_active, "modulate:a", 1.0, 0.2)
			if echo_status_label:
				echo_status_label.text = "ATIVO"
				echo_status_label.set("theme_override_colors/font_color", Color(0.3, 0.95, 1.0, 1.0))
		else:
			# Eco pronto (apagado, soquete escuro)
			var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.tween_property(echo_gem_active, "modulate:a", 0.0, 0.2)
			tw.chain().tween_callback(func(): echo_gem_active.visible = false)
			if echo_status_label:
				echo_status_label.text = "PRONTO"
				echo_status_label.set("theme_override_colors/font_color", Color(0.6, 0.7, 0.8, 0.65))
