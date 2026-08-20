extends Control

signal closed

var listening_action: String = ""

# Audio UI references
@onready var volume_slider: HSlider = %VolumeSlider if has_node("%VolumeSlider") else null
@onready var volume_label: Label = %VolumeLabel if has_node("%VolumeLabel") else null
@onready var mute_checkbox: CheckBox = %MuteCheckBox if has_node("%MuteCheckBox") else null

# Controls Buttons Map
@onready var btn_left: Button = %BtnLeft if has_node("%BtnLeft") else null
@onready var btn_right: Button = %BtnRight if has_node("%BtnRight") else null
@onready var btn_up: Button = %BtnUp if has_node("%BtnUp") else null
@onready var btn_down: Button = %BtnDown if has_node("%BtnDown") else null
@onready var btn_jump: Button = %BtnJump if has_node("%BtnJump") else null
@onready var btn_attack: Button = %BtnAttack if has_node("%BtnAttack") else null
@onready var btn_echo_create: Button = %BtnEchoCreate if has_node("%BtnEchoCreate") else null
@onready var btn_echo_teleport: Button = %BtnEchoTeleport if has_node("%BtnEchoTeleport") else null
@onready var btn_pause: Button = %BtnPause if has_node("%BtnPause") else null
@onready var listening_overlay: PanelContainer = %ListeningOverlay if has_node("%ListeningOverlay") else null
@onready var listening_label: Label = %ListeningLabel if has_node("%ListeningLabel") else null


func _ready() -> void:
	visible = false
	if listening_overlay:
		listening_overlay.visible = false
	
	if SettingsManager:
		SettingsManager.controls_changed.connect(refresh_ui)
		SettingsManager.volume_changed.connect(_on_settings_volume_changed)
	
	_connect_button_signals()
	refresh_ui()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	
	if listening_action != "":
		if event is InputEventKey and event.pressed and not event.is_echo():
			var code: Key = event.physical_keycode if event.physical_keycode != KEY_NONE else event.keycode
			if code == KEY_ESCAPE and listening_action != "pause":
				# Cancel remapping on Escape
				stop_listening()
			else:
				SettingsManager.rebind_action_key(listening_action, code)
				stop_listening()
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		_on_back_button_pressed()
		get_viewport().set_input_as_handled()


func open_menu() -> void:
	listening_action = ""
	if listening_overlay:
		listening_overlay.visible = false
	refresh_ui()
	visible = true


func refresh_ui() -> void:
	if not is_instance_valid(SettingsManager):
		return
	
	# Update Audio UI
	var eff_vol := SettingsManager.get_effective_volume()
	if volume_slider:
		volume_slider.set_value_no_signal(eff_vol * 100.0)
	if volume_label:
		volume_label.text = "%d%%" % int(eff_vol * 100.0)
	if mute_checkbox:
		mute_checkbox.set_pressed_no_signal(SettingsManager.is_muted)
	
	# Update Controls Buttons text
	_set_btn_text(btn_left, "ui_left")
	_set_btn_text(btn_right, "ui_right")
	_set_btn_text(btn_up, "ui_up")
	_set_btn_text(btn_down, "ui_down")
	_set_btn_text(btn_jump, "jump")
	_set_btn_text(btn_attack, "attack")
	_set_btn_text(btn_echo_create, "echo_create")
	_set_btn_text(btn_echo_teleport, "echo_collapse")
	_set_btn_text(btn_pause, "pause")


func _set_btn_text(btn: Button, action_name: String) -> void:
	if btn:
		btn.text = SettingsManager.get_action_key_name(action_name)


func _connect_button_signals() -> void:
	if btn_left: btn_left.pressed.connect(func(): start_listening("ui_left", "Mover Esquerda"))
	if btn_right: btn_right.pressed.connect(func(): start_listening("ui_right", "Mover Direita"))
	if btn_up: btn_up.pressed.connect(func(): start_listening("ui_up", "Subir Escada"))
	if btn_down: btn_down.pressed.connect(func(): start_listening("ui_down", "Descer Escada"))
	if btn_jump: btn_jump.pressed.connect(func(): start_listening("jump", "Pular"))
	if btn_attack: btn_attack.pressed.connect(func(): start_listening("attack", "Atacar / Rebater"))
	if btn_echo_create: btn_echo_create.pressed.connect(func(): start_listening("echo_create", "Invocar Eco"))
	if btn_echo_teleport: btn_echo_teleport.pressed.connect(func(): start_listening("echo_collapse", "Colapsar Eco / Teleportar"))
	if btn_pause: btn_pause.pressed.connect(func(): start_listening("pause", "Pausar Jogo"))


func start_listening(action_name: String, human_label: String) -> void:
	listening_action = action_name
	if listening_overlay and listening_label:
		listening_label.text = "Pressione uma tecla para [%s]...\n(ESC para cancelar)" % human_label
		listening_overlay.visible = true


func stop_listening() -> void:
	listening_action = ""
	if listening_overlay:
		listening_overlay.visible = false
	refresh_ui()


func _on_volume_slider_value_changed(value: float) -> void:
	var vol := value / 100.0
	if volume_label:
		volume_label.text = "%d%%" % int(value)
	if SettingsManager:
		SettingsManager.set_master_volume(vol)


func _on_mute_check_box_toggled(toggled_on: bool) -> void:
	if SettingsManager:
		SettingsManager.set_muted(toggled_on)


func _on_settings_volume_changed(new_vol: float) -> void:
	if volume_slider:
		volume_slider.set_value_no_signal(new_vol * 100.0)
	if volume_label:
		volume_label.text = "%d%%" % int(new_vol * 100.0)
	if mute_checkbox:
		mute_checkbox.set_pressed_no_signal(SettingsManager.is_muted)


func _on_reset_defaults_button_pressed() -> void:
	if SettingsManager:
		SettingsManager.reset_to_defaults()


func _on_back_button_pressed() -> void:
	if listening_action != "":
		stop_listening()
		return
	visible = false
	closed.emit()
