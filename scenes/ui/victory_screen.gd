extends Control


func _on_restart_button_pressed() -> void:
	GameState.current_floor_index = 1
	get_tree().call_deferred(&"change_scene_to_file", "res://scenes/ui/title_screen.tscn")
