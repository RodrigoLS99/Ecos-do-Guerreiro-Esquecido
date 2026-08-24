extends Control

@onready var panel: PanelContainer = $CenterContainer/PanelContainer if has_node("CenterContainer/PanelContainer") else null


func _ready() -> void:
	if AudioManager:
		AudioManager.play_ambient_track("tragedy")
	
	if panel != null:
		panel.modulate.a = 0.0
		var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(panel, "modulate:a", 1.0, 1.2)


func _on_restart_button_pressed() -> void:
	if AudioManager:
		AudioManager.play_sfx("button_click")
	GameState.current_floor_index = 1
	get_tree().call_deferred(&"change_scene_to_file", "res://scenes/ui/title_screen.tscn")
