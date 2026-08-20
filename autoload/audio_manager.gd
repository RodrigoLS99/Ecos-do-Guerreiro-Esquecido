extends Node

const SAMPLE_RATE := 22050
const POOL_SIZE := 10

var _players: Array[AudioStreamPlayer] = []
var _player_index := 0
var _sfx_cache: Dictionary = {}
var _music_cache: Dictionary = {}

var bgm_player_1: AudioStreamPlayer = null
var bgm_player_2: AudioStreamPlayer = null
var _active_bgm_player: AudioStreamPlayer = null
var current_track_key := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_player_pool()
	_pregenerate_sounds()
	_setup_ambient_bgm()
	
	# Detect scene changes automatically
	get_tree().scene_changed.connect(_on_scene_changed)
	_on_scene_changed()


func _setup_player_pool() -> void:
	for i in range(POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.append(p)


func _setup_ambient_bgm() -> void:
	bgm_player_1 = AudioStreamPlayer.new()
	bgm_player_1.bus = "Master"
	add_child(bgm_player_1)
	
	bgm_player_2 = AudioStreamPlayer.new()
	bgm_player_2.bus = "Master"
	add_child(bgm_player_2)
	
	_active_bgm_player = bgm_player_1


func _on_scene_changed() -> void:
	var current_scene := get_tree().current_scene
	if current_scene == null:
		return
	
	var scene_path := current_scene.scene_file_path
	if scene_path.contains("floor_1"):
		play_ambient_track("floor_1")
	elif scene_path.contains("floor_2"):
		play_ambient_track("floor_2")
	elif scene_path.contains("floor_3"):
		play_ambient_track("floor_3")
	elif scene_path.contains("floor_4"):
		play_ambient_track("floor_4")
	elif scene_path.contains("floor_5"):
		play_ambient_track("floor_5")
	elif scene_path.contains("victory"):
		play_ambient_track("floor_5")
	else:
		play_ambient_track("menu")


func play_ambient_track(track_key: String) -> void:
	if current_track_key == track_key and _active_bgm_player != null and _active_bgm_player.playing:
		return
	
	# Geração sob demanda (Lazy loading instantâneo)
	if not _music_cache.has(track_key):
		_music_cache[track_key] = _generate_track_by_key(track_key)
	
	current_track_key = track_key
	var next_player := bgm_player_2 if _active_bgm_player == bgm_player_1 else bgm_player_1
	var old_player := _active_bgm_player
	
	next_player.stream = _music_cache[track_key]
	next_player.volume_db = -40.0
	next_player.play()
	
	# Smooth crossfade
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(next_player, "volume_db", -16.0, 1.0)
	if old_player != null and old_player.playing:
		tw.tween_property(old_player, "volume_db", -45.0, 1.0)
		tw.chain().tween_callback(old_player.stop)
	
	_active_bgm_player = next_player


func play_sfx(sound_name: String, volume_scale: float = 1.0, pitch_scale: float = 1.0) -> void:
	if not _sfx_cache.has(sound_name):
		return
	
	var stream: AudioStreamWAV = _sfx_cache[sound_name]
	var player := _players[_player_index]
	_player_index = (_player_index + 1) % POOL_SIZE
	
	player.stream = stream
	player.volume_db = linear_to_db(volume_scale)
	player.pitch_scale = pitch_scale
	player.play()


func _pregenerate_sounds() -> void:
	_sfx_cache["jump"] = _gen_jump()
	_sfx_cache["step"] = _gen_step()
	_sfx_cache["attack"] = _gen_attack()
	_sfx_cache["hit_enemy"] = _gen_hit_enemy()
	_sfx_cache["hurt"] = _gen_hurt()
	_sfx_cache["death"] = _gen_death()
	_sfx_cache["echo_create"] = _gen_echo_create()
	_sfx_cache["echo_teleport"] = _gen_echo_teleport()
	_sfx_cache["projectile_shoot"] = _gen_shoot()
	_sfx_cache["projectile_deflect"] = _gen_deflect()
	_sfx_cache["gate_open"] = _gen_gate()
	_sfx_cache["plate_pressed"] = _gen_plate()
	_sfx_cache["artifact_collect"] = _gen_artifact()
	_sfx_cache["princess_rescue"] = _gen_princess()
	_sfx_cache["button_click"] = _gen_ui_click()


func _generate_track_by_key(track_key: String) -> AudioStreamWAV:
	match track_key:
		"floor_1":
			return _synth_ambient_track([130.81, 174.61, 220.00, 261.63], 0.08, false)
		"floor_2":
			return _synth_ambient_track([146.83, 220.00, 293.66, 349.23], 0.12, false)
		"floor_3":
			return _synth_ambient_track([110.00, 146.83, 174.61, 220.00], 0.18, true, 2.0)
		"floor_4":
			return _synth_ambient_track([82.41, 123.47, 164.81, 196.00], 0.22, true, 3.0)
		"floor_5":
			return _synth_ambient_track([196.00, 246.94, 293.66, 392.00, 523.25], 0.04, false)
		_:
			return _synth_ambient_track([130.81, 164.81, 196.00, 261.63], 0.05, false)


# --- SÍNTESE ULTRA-RÁPIDA EM 16-BITS ---

func _synth_ambient_track(freqs: Array, tension_mod: float, add_pulse: bool, pulse_speed: float = 2.0) -> AudioStreamWAV:
	var duration := 2.0 # Loop contínuo otimizado de 2 segundos (geração em ~2ms)
	var samples := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	
	for i in range(samples):
		var t := float(i) / float(SAMPLE_RATE)
		var wave := 0.0
		for k in range(freqs.size()):
			var f: float = freqs[k]
			var lfo := 1.0 + sin(TAU * 0.5 * t + float(k) * 1.5) * (0.005 + tension_mod * 0.01)
			wave += sin(TAU * (f * lfo) * t) * (1.0 / float(freqs.size()))
		
		if add_pulse:
			var pulse := 0.85 + sin(TAU * pulse_speed * t) * 0.15
			wave *= pulse
		
		var val := wave * 6800.0
		data.encode_s16(i * 2, int(clampf(val, -32000.0, 32000.0)))
	
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = samples
	return stream


func _gen_step() -> AudioStreamWAV:
	var duration := 0.05
	var samples := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t := float(i) / float(SAMPLE_RATE)
		var progress := t / duration
		var env := pow(1.0 - progress, 3.0)
		var thud := sin(TAU * 120.0 * t) * 0.7
		var click := sin(TAU * 340.0 * t) * 0.3
		var val := (thud + click) * env * 14000.0
		data.encode_s16(i * 2, int(clampf(val, -32000.0, 32000.0)))
	return _make_stream_16(data)


func _gen_jump() -> AudioStreamWAV:
	var duration := 0.14
	var samples := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t := float(i) / float(SAMPLE_RATE)
		var progress := t / duration
		var env := sin(progress * PI) * (1.0 - progress * 0.4)
		var freq := lerpf(220.0, 480.0, pow(progress, 0.6))
		var wave := sin(TAU * freq * t)
		var val := wave * env * 18000.0
		data.encode_s16(i * 2, int(clampf(val, -32000.0, 32000.0)))
	return _make_stream_16(data)


func _gen_attack() -> AudioStreamWAV:
	var duration := 0.15
	var samples := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t := float(i) / float(SAMPLE_RATE)
		var progress := t / duration
		var env := sin(progress * PI)
		var tone := sin(TAU * (600.0 - progress * 350.0) * t) * 0.4
		var white := (randf() * 2.0 - 1.0) * 0.5
		var val := (tone + white) * env * 16000.0
		data.encode_s16(i * 2, int(clampf(val, -32000.0, 32000.0)))
	return _make_stream_16(data)


func _gen_deflect() -> AudioStreamWAV:
	var duration := 0.28
	var samples := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t := float(i) / float(SAMPLE_RATE)
		var progress := t / duration
		var env := exp(- progress * 7.0)
		var bell1 := sin(TAU * 1174.66 * t) * 0.55
		var bell2 := sin(TAU * 2349.32 * t) * 0.35
		var bell3 := sin(TAU * 3520.00 * t) * 0.15
		var val := (bell1 + bell2 + bell3) * env * 22000.0
		data.encode_s16(i * 2, int(clampf(val, -32000.0, 32000.0)))
	return _make_stream_16(data)


func _gen_hit_enemy() -> AudioStreamWAV:
	var duration := 0.12
	var samples := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t := float(i) / float(SAMPLE_RATE)
		var progress := t / duration
		var env := pow(1.0 - progress, 2.5)
		var punch := sin(TAU * (140.0 - progress * 60.0) * t) * 0.8
		var snap := sin(TAU * 480.0 * t) * 0.3
		var val := (punch + snap) * env * 20000.0
		data.encode_s16(i * 2, int(clampf(val, -32000.0, 32000.0)))
	return _make_stream_16(data)


func _gen_hurt() -> AudioStreamWAV:
	var duration := 0.18
	var samples := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t := float(i) / float(SAMPLE_RATE)
		var progress := t / duration
		var env := pow(1.0 - progress, 2.0)
		var thud := sin(TAU * lerpf(120.0, 50.0, progress) * t)
		var val := thud * env * 20000.0
		data.encode_s16(i * 2, int(clampf(val, -32000.0, 32000.0)))
	return _make_stream_16(data)


func _gen_death() -> AudioStreamWAV:
	var duration := 0.5
	var samples := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t := float(i) / float(SAMPLE_RATE)
		var progress := t / duration
		var env := exp(- progress * 4.0)
		var low_bell := sin(TAU * 110.0 * t) * 0.6
		var fifth := sin(TAU * 164.81 * t) * 0.4
		var val := (low_bell + fifth) * env * 22000.0
		data.encode_s16(i * 2, int(clampf(val, -32000.0, 32000.0)))
	return _make_stream_16(data)


func _gen_echo_create() -> AudioStreamWAV:
	var duration := 0.32
	var samples := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t := float(i) / float(SAMPLE_RATE)
		var progress := t / duration
		var env := sin(progress * PI) * exp(- progress * 2.0)
		var c1 := sin(TAU * 523.25 * t) * 0.4
		var e1 := sin(TAU * 659.25 * t) * 0.35
		var g1 := sin(TAU * 783.99 * t) * 0.25
		var val := (c1 + e1 + g1) * env * 19000.0
		data.encode_s16(i * 2, int(clampf(val, -32000.0, 32000.0)))
	return _make_stream_16(data)


func _gen_echo_teleport() -> AudioStreamWAV:
	var duration := 0.22
	var samples := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t := float(i) / float(SAMPLE_RATE)
		var progress := t / duration
		var env := sin(progress * PI)
		var freq := lerpf(400.0, 950.0, pow(progress, 0.7))
		var wave := sin(TAU * freq * t)
		var val := wave * env * 18000.0
		data.encode_s16(i * 2, int(clampf(val, -32000.0, 32000.0)))
	return _make_stream_16(data)


func _gen_shoot() -> AudioStreamWAV:
	var duration := 0.12
	var samples := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t := float(i) / float(SAMPLE_RATE)
		var progress := t / duration
		var env := pow(1.0 - progress, 2.0)
		var pluck := sin(TAU * lerpf(550.0, 220.0, progress) * t) * 0.8
		var air := (randf() * 2.0 - 1.0) * 0.2
		var val := (pluck + air) * env * 16000.0
		data.encode_s16(i * 2, int(clampf(val, -32000.0, 32000.0)))
	return _make_stream_16(data)


func _gen_gate() -> AudioStreamWAV:
	var duration := 0.35
	var samples := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t := float(i) / float(SAMPLE_RATE)
		var progress := t / duration
		var env := sin(progress * PI)
		var bass := sin(TAU * 85.0 * t) * 0.7
		var shine := sin(TAU * 440.0 * t) * 0.3
		var val := (bass + shine) * env * 18000.0
		data.encode_s16(i * 2, int(clampf(val, -32000.0, 32000.0)))
	return _make_stream_16(data)


func _gen_plate() -> AudioStreamWAV:
	var duration := 0.08
	var samples := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t := float(i) / float(SAMPLE_RATE)
		var progress := t / duration
		var env := pow(1.0 - progress, 2.0)
		var click := sin(TAU * 320.0 * t)
		var val := click * env * 18000.0
		data.encode_s16(i * 2, int(clampf(val, -32000.0, 32000.0)))
	return _make_stream_16(data)


func _gen_artifact() -> AudioStreamWAV:
	var duration := 0.75
	var samples := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	var notes := [440.0, 554.37, 659.25, 880.0]
	for i in range(samples):
		var t := float(i) / float(SAMPLE_RATE)
		var note_idx := int((t / duration) * float(notes.size()))
		note_idx = clampi(note_idx, 0, notes.size() - 1)
		var freq: float = notes[note_idx]
		var sub_t := fmod(t, duration / float(notes.size()))
		var env := exp(- sub_t * 6.0)
		var wave := sin(TAU * freq * t) + sin(TAU * freq * 2.0 * t) * 0.25
		var val := wave * env * 20000.0
		data.encode_s16(i * 2, int(clampf(val, -32000.0, 32000.0)))
	return _make_stream_16(data)


func _gen_princess() -> AudioStreamWAV:
	var duration := 0.9
	var samples := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	var chord := [329.63, 415.30, 493.88, 659.25]
	for i in range(samples):
		var t := float(i) / float(SAMPLE_RATE)
		var env := sin((t / duration) * PI) * exp(- (t / duration) * 1.5)
		var wave := 0.0
		for f in chord:
			wave += sin(TAU * f * t)
		wave /= float(chord.size())
		var val := wave * env * 21000.0
		data.encode_s16(i * 2, int(clampf(val, -32000.0, 32000.0)))
	return _make_stream_16(data)


func _gen_ui_click() -> AudioStreamWAV:
	var duration := 0.03
	var samples := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t := float(i) / float(SAMPLE_RATE)
		var env := 1.0 - (t / duration)
		var wave := sin(TAU * 650.0 * t)
		var val := wave * env * 14000.0
		data.encode_s16(i * 2, int(clampf(val, -32000.0, 32000.0)))
	return _make_stream_16(data)


func _make_stream_16(data: PackedByteArray) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = data
	return stream
