extends Node

var current_floor_index := 1
const FLOOR_PATHS: Array[String] = [
	"res://scenes/floors/floor_1.tscn",
	"res://scenes/floors/floor_2.tscn",
	"res://scenes/floors/floor_3.tscn",
	"res://scenes/floors/floor_4.tscn",
	"res://scenes/floors/floor_5.tscn",
]


func start_game() -> void:
	current_floor_index = 1
	respawn_current_floor()


func respawn_current_floor() -> void:
	_sync_floor_index_from_current_scene()

	if current_floor_index >= 1 and current_floor_index <= FLOOR_PATHS.size() and ResourceLoader.exists(FLOOR_PATHS[current_floor_index - 1]):
		get_tree().call_deferred(&"change_scene_to_file", FLOOR_PATHS[current_floor_index - 1])
	elif ResourceLoader.exists("res://scenes/test/test_arena.tscn"):
		get_tree().call_deferred(&"change_scene_to_file", "res://scenes/test/test_arena.tscn")
	else:
		get_tree().call_deferred(&"reload_current_scene")


func go_to_next_floor() -> void:
	_sync_floor_index_from_current_scene()
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
		elif ResourceLoader.exists("res://scenes/test/test_arena.tscn"):
			get_tree().call_deferred(&"change_scene_to_file", "res://scenes/test/test_arena.tscn")
		else:
			get_tree().call_deferred(&"reload_current_scene")


func _sync_floor_index_from_current_scene() -> void:
	var current_scene := get_tree().current_scene
	if current_scene != null and current_scene.scene_file_path:
		for i in range(FLOOR_PATHS.size()):
			if FLOOR_PATHS[i] == current_scene.scene_file_path:
				current_floor_index = i + 1
				return
