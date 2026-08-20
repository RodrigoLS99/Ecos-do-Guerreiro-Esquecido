extends Node

signal controls_changed
signal volume_changed(new_volume: float)

const SAVE_PATH := "user://settings.cfg"

const DEFAULT_KEYS := {
	"ui_left": KEY_A,
	"ui_right": KEY_D,
	"ui_up": KEY_W,
	"ui_down": KEY_S,
	"jump": KEY_SPACE,
	"attack": KEY_X,
	"echo_create": KEY_C,
	"echo_collapse": KEY_V,
	"pause": KEY_ESCAPE,
}

const ACTION_LABELS := {
	"ui_left": "Mover para Esquerda",
	"ui_right": "Mover para Direita",
	"ui_up": "Subir / Escada",
	"ui_down": "Descer / Agachar",
	"jump": "Pular",
	"attack": "Atacar / Rebater",
	"echo_create": "Invocar Eco",
	"echo_collapse": "Teletransportar / Colapsar",
	"pause": "Pausar Jogo",
}

var master_volume: float = 1.0
var is_muted: bool = false


func _ready() -> void:
	# Ensure pause action exists in InputMap
	if not InputMap.has_action("pause"):
		InputMap.add_action("pause")
		var ev_esc := InputEventKey.new()
		ev_esc.physical_keycode = KEY_ESCAPE
		InputMap.action_add_event("pause", ev_esc)
		var ev_p := InputEventKey.new()
		ev_p.physical_keycode = KEY_P
		InputMap.action_add_event("pause", ev_p)

	load_settings()
	apply_audio_volume()


# --- GESTÃO DE ÁUDIO ---

func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	if is_muted and master_volume > 0.0:
		is_muted = false
	apply_audio_volume()
	save_settings()
	volume_changed.emit(get_effective_volume())


func set_muted(muted: bool) -> void:
	is_muted = muted
	apply_audio_volume()
	save_settings()
	volume_changed.emit(get_effective_volume())


func get_effective_volume() -> float:
	return 0.0 if is_muted else master_volume


func apply_audio_volume() -> void:
	var bus_idx := AudioServer.get_bus_index("Master")
	if bus_idx >= 0:
		var effective := get_effective_volume()
		AudioServer.set_bus_mute(bus_idx, is_muted or effective <= 0.001)
		var db := linear_to_db(effective) if effective > 0.001 else -80.0
		AudioServer.set_bus_volume_db(bus_idx, db)


# --- GESTÃO DE CONTROLES (COM ALTERNÂNCIA/SWAP) ---

func rebind_action_key(action_name: String, new_keycode: Key) -> void:
	var old_keycode := get_action_keycode(action_name)
	if old_keycode == new_keycode:
		return

	# Verifica se a tecla nova já pertence a outra ação configurável
	var conflicting_action := ""
	for act in DEFAULT_KEYS:
		if act != action_name and act != "pause":
			if get_action_keycode(act) == new_keycode:
				conflicting_action = act
				break

	# Se houver conflito, alterna as teclas entre as duas ações
	if conflicting_action != "" and old_keycode != KEY_NONE:
		_set_raw_action_key(conflicting_action, old_keycode)

	_set_raw_action_key(action_name, new_keycode)

	save_settings()
	controls_changed.emit()


func _set_raw_action_key(action_name: String, keycode: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)

	var events := InputMap.action_get_events(action_name)
	for ev in events:
		if ev is InputEventKey:
			InputMap.action_erase_event(action_name, ev)

	var new_event := InputEventKey.new()
	new_event.physical_keycode = keycode
	InputMap.action_add_event(action_name, new_event)

	if action_name == "pause" and keycode != KEY_P:
		var ev_p := InputEventKey.new()
		ev_p.physical_keycode = KEY_P
		InputMap.action_add_event("pause", ev_p)


func get_action_keycode(action_name: String) -> Key:
	if not InputMap.has_action(action_name):
		return KEY_NONE
	var events := InputMap.action_get_events(action_name)
	for ev in events:
		if ev is InputEventKey:
			return ev.physical_keycode if ev.physical_keycode != KEY_NONE else ev.keycode
	return KEY_NONE


func get_action_key_name(action_name: String) -> String:
	var code := get_action_keycode(action_name)
	if code == KEY_NONE:
		return "?"
	return format_key_code(code)


func format_key_code(code: Key) -> String:
	match code:
		KEY_SPACE:
			return "Espaço"
		KEY_ESCAPE:
			return "ESC"
		KEY_ENTER:
			return "Enter"
		KEY_TAB:
			return "Tab"
		KEY_SHIFT:
			return "Shift"
		KEY_CTRL:
			return "Ctrl"
		KEY_ALT:
			return "Alt"
		KEY_LEFT:
			return "Seta Esq"
		KEY_RIGHT:
			return "Seta Dir"
		KEY_UP:
			return "Seta Cima"
		KEY_DOWN:
			return "Seta Baixo"
		_:
			return OS.get_keycode_string(code).to_upper()


func format_prompt(template: String) -> String:
	var result := template
	result = result.replace("{ui_left}", get_action_key_name("ui_left"))
	result = result.replace("{ui_right}", get_action_key_name("ui_right"))
	result = result.replace("{ui_up}", get_action_key_name("ui_up"))
	result = result.replace("{ui_down}", get_action_key_name("ui_down"))
	result = result.replace("{jump}", get_action_key_name("jump"))
	result = result.replace("{attack}", get_action_key_name("attack"))
	result = result.replace("{echo_create}", get_action_key_name("echo_create"))
	result = result.replace("{echo_collapse}", get_action_key_name("echo_collapse"))
	result = result.replace("{pause}", get_action_key_name("pause"))
	return result


func reset_to_defaults() -> void:
	master_volume = 1.0
	is_muted = false
	apply_audio_volume()

	for action_name in DEFAULT_KEYS:
		var keycode: Key = DEFAULT_KEYS[action_name]
		_set_raw_action_key(action_name, keycode)

	save_settings()
	controls_changed.emit()
	volume_changed.emit(master_volume)


# --- PERSISTÊNCIA (CONFIGFILE) ---

func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "is_muted", is_muted)

	for action_name in DEFAULT_KEYS:
		var code := get_action_keycode(action_name)
		if code != KEY_NONE:
			config.set_value("controls", action_name, int(code))

	config.save(SAVE_PATH)


func load_settings() -> void:
	var config := ConfigFile.new()
	var err := config.load(SAVE_PATH)
	if err != OK:
		return

	master_volume = config.get_value("audio", "master_volume", 1.0)
	is_muted = config.get_value("audio", "is_muted", false)

	for action_name in DEFAULT_KEYS:
		if config.has_section_key("controls", action_name):
			var keycode_int: int = config.get_value("controls", action_name, int(DEFAULT_KEYS[action_name]))
			var keycode: Key = keycode_int as Key
			_set_raw_action_key(action_name, keycode)
