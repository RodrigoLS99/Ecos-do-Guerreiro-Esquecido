extends Control

@onready var help_dialog: Control = $HelpDialog if has_node("HelpDialog") else null
@onready var options_menu: Control = $OptionsMenu if has_node("OptionsMenu") else null
@onready var main_panel: PanelContainer = $CenterContainer/MainPanel if has_node("CenterContainer/MainPanel") else null
@onready var echo_particles: Node2D = $EchoParticles if has_node("EchoParticles") else null
@onready var emblem_label: Label = $CenterContainer/MainPanel/MarginContainer/VBoxContainer/TitleBox/EmblemLabel if has_node("CenterContainer/MainPanel/MarginContainer/VBoxContainer/TitleBox/EmblemLabel") else null

var time_passed := 0.0


func _ready() -> void:
	if AudioManager:
		AudioManager.play_ambient_track("menu")
	
	if main_panel != null:
		main_panel.modulate.a = 0.0
		var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(main_panel, "modulate:a", 1.0, 1.0)


func _process(delta: float) -> void:
	time_passed += delta
	
	# Animação suave de partículas de mana
	if echo_particles != null:
		for i in range(echo_particles.get_child_count()):
			var child := echo_particles.get_child(i) as Node2D
			if child != null:
				child.position.y -= delta * (15.0 + float(i) * 5.0)
				child.position.x += sin(time_passed * 2.0 + float(i)) * 0.4
				if child.position.y < 120.0:
					child.position.y = 580.0
	
	# Pulso suave do emblema
	if emblem_label != null:
		emblem_label.modulate.a = 0.7 + sin(time_passed * 3.0) * 0.3


func _on_play_button_pressed() -> void:
	if AudioManager:
		AudioManager.play_sfx("button_click")
	var prologue_path := "res://scenes/ui/prologue_screen.tscn"
	if ResourceLoader.exists(prologue_path):
		get_tree().change_scene_to_file(prologue_path)
	else:
		GameState.start_game()


func _on_options_button_pressed() -> void:
	if AudioManager:
		AudioManager.play_sfx("button_click")
	if options_menu:
		options_menu.open_menu()


func _on_help_button_pressed() -> void:
	if AudioManager:
		AudioManager.play_sfx("button_click")
	if help_dialog:
		help_dialog.open_dialog()


func _on_quit_button_pressed() -> void:
	if AudioManager:
		AudioManager.play_sfx("button_click")
	get_tree().quit()
