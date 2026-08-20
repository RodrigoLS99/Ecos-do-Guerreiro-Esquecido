extends Control

@onready var help_dialog: Control = $HelpDialog if has_node("HelpDialog") else null
@onready var options_menu: Control = $OptionsMenu if has_node("OptionsMenu") else null


func _on_play_button_pressed() -> void:
	GameState.start_game()


func _on_options_button_pressed() -> void:
	if options_menu:
		options_menu.open_menu()


func _on_help_button_pressed() -> void:
	if help_dialog:
		help_dialog.open_dialog()
