extends Control

signal closed

@onready var controls_list: VBoxContainer = $Panel/MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/ControlsGrid/LabelsContainer if has_node("Panel/MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/ControlsGrid/LabelsContainer") else null

# Labels references to update dynamically
@onready var lbl_move: Label = %LblMove if has_node("%LblMove") else null
@onready var lbl_jump: Label = %LblJump if has_node("%LblJump") else null
@onready var lbl_ladder: Label = %LblLadder if has_node("%LblLadder") else null
@onready var lbl_attack: Label = %LblAttack if has_node("%LblAttack") else null
@onready var lbl_echo_create: Label = %LblEchoCreate if has_node("%LblEchoCreate") else null
@onready var lbl_echo_teleport: Label = %LblEchoTeleport if has_node("%LblEchoTeleport") else null
@onready var lbl_pause: Label = %LblPause if has_node("%LblPause") else null


func _ready() -> void:
	visible = false
	if SettingsManager:
		SettingsManager.controls_changed.connect(refresh_controls_display)
	refresh_controls_display()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		_on_close_button_pressed()
		get_viewport().set_input_as_handled()


func open_dialog() -> void:
	refresh_controls_display()
	visible = true


func refresh_controls_display() -> void:
	if not is_instance_valid(SettingsManager):
		return
	
	if lbl_move:
		lbl_move.text = "%s / %s" % [SettingsManager.get_action_key_name("ui_left"), SettingsManager.get_action_key_name("ui_right")]
	if lbl_jump:
		lbl_jump.text = SettingsManager.get_action_key_name("jump")
	if lbl_ladder:
		lbl_ladder.text = "%s / %s" % [SettingsManager.get_action_key_name("ui_up"), SettingsManager.get_action_key_name("ui_down")]
	if lbl_attack:
		lbl_attack.text = SettingsManager.get_action_key_name("attack")
	if lbl_echo_create:
		lbl_echo_create.text = SettingsManager.get_action_key_name("echo_create")
	if lbl_echo_teleport:
		lbl_echo_teleport.text = SettingsManager.get_action_key_name("echo_collapse")
	if lbl_pause:
		lbl_pause.text = SettingsManager.get_action_key_name("pause")


func _on_close_button_pressed() -> void:
	visible = false
	closed.emit()
