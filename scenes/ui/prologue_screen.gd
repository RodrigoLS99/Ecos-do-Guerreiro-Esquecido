extends Control

@onready var continue_button: Button = %ContinueButton if has_node("%ContinueButton") else null
@onready var story_label: Label = %StoryLabel if has_node("%StoryLabel") else null


func _ready() -> void:
	# Subtle fade-in of the narrative text
	if story_label:
		story_label.modulate.a = 0.0
		var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(story_label, "modulate:a", 1.0, 1.0)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump") or event.is_action_pressed("ui_accept"):
		_on_continue_button_pressed()
		get_viewport().set_input_as_handled()


func _on_continue_button_pressed() -> void:
	GameState.start_game()
