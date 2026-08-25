extends CanvasLayer

@onready var menu_root: Control = $MenuRoot
@onready var options_menu: Control = $OptionsMenu if has_node("OptionsMenu") else null
@onready var help_dialog: Control = $HelpDialog if has_node("HelpDialog") else null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	menu_root.visible = false
	if options_menu:
		options_menu.visible = false
		options_menu.closed.connect(_on_sub_menu_closed)
	if help_dialog:
		help_dialog.visible = false
		help_dialog.closed.connect(_on_sub_menu_closed)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if options_menu and options_menu.visible:
			options_menu._on_back_button_pressed()
			get_viewport().set_input_as_handled()
			return
		if help_dialog and help_dialog.visible:
			help_dialog._on_close_button_pressed()
			get_viewport().set_input_as_handled()
			return
		
		toggle_pause()
		get_viewport().set_input_as_handled()


func toggle_pause() -> void:
	if get_tree().paused:
		resume_game()
	else:
		pause_game()


func pause_game() -> void:
	get_tree().paused = true
	menu_root.visible = true


func resume_game() -> void:
	if options_menu:
		options_menu.visible = false
	if help_dialog:
		help_dialog.visible = false
	menu_root.visible = false
	get_tree().paused = false


func _on_sub_menu_closed() -> void:
	menu_root.visible = true


func _on_resume_button_pressed() -> void:
	resume_game()


func _on_options_button_pressed() -> void:
	menu_root.visible = false
	if options_menu:
		options_menu.open_menu()


func _on_help_button_pressed() -> void:
	menu_root.visible = false
	if help_dialog:
		help_dialog.open_dialog()


func _on_restart_floor_button_pressed() -> void:
	resume_game()
	GameState.respawn_current_floor()


func _on_main_menu_button_pressed() -> void:
	resume_game()
	get_tree().change_scene_to_file("res://scenes/ui/title_screen.tscn")
