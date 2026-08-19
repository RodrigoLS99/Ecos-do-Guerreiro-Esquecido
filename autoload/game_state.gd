extends Node

var current_floor_index := 1
const FLOOR_PATHS: Array[String] = [
	"res://scenes/floors/floor_1.tscn",
	"res://scenes/floors/floor_2.tscn",
	"res://scenes/floors/floor_3.tscn",
	"res://scenes/floors/floor_4.tscn",
	"res://scenes/floors/floor_5.tscn",
]


func respawn_current_floor() -> void:
	if current_floor_index >= 1 and current_floor_index <= FLOOR_PATHS.size() and ResourceLoader.exists(FLOOR_PATHS[current_floor_index - 1]):
		get_tree().call_deferred(&"change_scene_to_file", FLOOR_PATHS[current_floor_index - 1])
	else:
		get_tree().call_deferred(&"reload_current_scene")


func go_to_next_floor() -> void:
	current_floor_index += 1
	if current_floor_index > FLOOR_PATHS.size():
		var victory_path := "res://scenes/ui/victory_screen.tscn"
		if ResourceLoader.exists(victory_path):
			get_tree().call_deferred(&"change_scene_to_file", victory_path)
		else:
			get_tree().call_deferred(&"reload_current_scene")
	else:
		if ResourceLoader.exists(FLOOR_PATHS[current_floor_index - 1]):
			get_tree().call_deferred(&"change_scene_to_file", FLOOR_PATHS[current_floor_index - 1])
		else:
			get_tree().call_deferred(&"reload_current_scene")
