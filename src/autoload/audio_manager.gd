extends Node

const SAMPLE_RATE := 22050
const POOL_SIZE := 12

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
		play_ambient_track("victory")
	elif scene_path.contains("tragedy"):
		play_ambient_track("tragedy")
	elif scene_path.contains("title_screen") or scene_path.contains("prologue"):
		play_ambient_track("menu")
	else:
		play_ambient_track("menu")


func play_ambient_track(track_key: String) -> void:
	if current_track_key == track_key and _active_bgm_player != null and _active_bgm_player.playing:
		return
	
	if not _music_cache.has(track_key):
		_music_cache[track_key] = _generate_track_by_key(track_key)
	
	current_track_key = track_key
	var next_player := bgm_player_2 if _active_bgm_player == bgm_player_1 else bgm_player_1
	var old_player := _active_bgm_player
	
	next_player.stream = _music_cache[track_key]
	next_player.volume_db = -35.0
	next_player.play()
	
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(next_player, "volume_db", -7.0, 0.8)
	if old_player != null and old_player.playing:
		tw.tween_property(old_player, "volume_db", -40.0, 0.8)
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


func play_sfx_at_position(sound_name: String, source_pos: Vector2, max_dist: float = 600.0, volume_scale: float = 1.0, pitch_scale: float = 1.0) -> void:
	var listener_pos := Vector2.ZERO
	var player = get_tree().get_first_node_in_group(&"player")
	if player != null and is_instance_valid(player):
		listener_pos = player.global_position
	else:
		var cam = get_viewport().get_camera_2d()
		if cam != null:
			listener_pos = cam.global_position

	var dist := listener_pos.distance_to(source_pos)
	if dist > max_dist:
		return

	var att := clampf(1.0 - (dist / max_dist), 0.0, 1.0)
	att = pow(att, 1.5)
	if att < 0.05:
		return

	play_sfx(sound_name, volume_scale * att, pitch_scale)


func _pregenerate_sounds() -> void:
	_sfx_cache["jump"] = _gen_jump()
	_sfx_cache["step"] = _gen_step()
	_sfx_cache["ladder_climb"] = _gen_ladder_climb()
	_sfx_cache["attack"] = _gen_attack()
	_sfx_cache["hit_enemy"] = _gen_hit_enemy()
	_sfx_cache["hurt"] = _gen_hurt()
	_sfx_cache["death"] = _gen_player_death_scream()
	_sfx_cache["player_death"] = _sfx_cache["death"]
	_sfx_cache["fall_death"] = _gen_fall_death_scream()
	_sfx_cache["enemy_death"] = _gen_enemy_death_scream()
	_sfx_cache["echo_create"] = _gen_echo_create()
	_sfx_cache["echo_teleport"] = _gen_echo_teleport()
	_sfx_cache["projectile_shoot"] = _gen_shoot()
	_sfx_cache["projectile_deflect"] = _gen_deflect()
	_sfx_cache["projectile_parry"] = _sfx_cache["projectile_deflect"]
	_sfx_cache["gate_open"] = _gen_gate()
	_sfx_cache["plate_pressed"] = _gen_plate()
	_sfx_cache["artifact_collect"] = _gen_artifact()
	_sfx_cache["princess_rescue"] = _gen_princess()
	_sfx_cache["princess_hit"] = _gen_princess_hit()
	_sfx_cache["button_click"] = _gen_ui_click()


func _generate_track_by_key(track_key: String) -> AudioStreamWAV:
	match track_key:
		"floor_1":
			return _synth_floor_1_track()
		"floor_2":
			return _synth_floor_2_track()
		"floor_3":
			return _synth_floor_3_track() # Recebe a faixa intensa e ritmada anterior
		"floor_4":
			return _synth_floor_4_track() # Nova faixa aterrorizante, pesada e sombria
		"floor_5":
			return _synth_floor_5_track() # Nova harmonia celestial pura e melodica
		"victory":
			return _synth_victory_track()
		"tragedy":
			return _synth_tragedy_track() # Réquiem fúnebre triste e tocante
		_:
			return _synth_menu_track()


# --- SÍNTESE MUSICAL DEDICADA (HARMONIA ACÚSTICA, SEM FADIGA, 100% LOOP CONTÍNUO) ---

# Andar 1: Exploração Ancestral e Nobre (Modo Dórico, arpejos de harpa serenos)
func _synth_floor_1_track() -> AudioStreamWAV:
	var duration := 4.0
	var samples := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	# Frequências harmonizadas (múltiplos exatos de 0.25 Hz para loop sem estalo)
	var pad_freqs := [130.75, 196.00, 261.50] # C3, G3, C4
	var arp_notes := [261.50, 329.50, 392.00, 523.25, 392.00, 329.50, 261.50, 196.00]
	
	for i in range(samples):
		var t := float(i) / float(SAMPLE_RATE)
		# Pad harmônico contínuo
		var pad := 0.0
		for f in pad_freqs:
			pad += sin(TAU * f * t) * 0.3
		
		# 8 notas arpejadas com envelope suave individual (evita descontinuidade)
		var step_idx := int((t / duration) * 8.0) % 8
		var step_t := fmod(t, duration / 8.0)
		var arp_f: float = arp_notes[step_idx]
		var env := sin((step_t / (duration / 8.0)) * PI) * exp(- step_t * 5.0)
		var arp := sin(TAU * arp_f * t) * env
		
		var breath := 0.85 + sin(TAU * 0.5 * t) * 0.15
		var mix := (pad * 0.55 + arp * 0.45) * breath * 16500.0
		data.encode_s16(i * 2, int(clampf(mix, -32000.0, 32000.0)))
	
	return _make_stream_16(data, true)


# Andar 2: Desgaste e Tensão Mística Crescente (Sub-grave, eco rítmico)
func _synth_floor_2_track() -> AudioStreamWAV:
	var duration := 4.0
	var samples := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	var pad_freqs := [110.00, 164.75, 220.00] # A2, E3, A3
	var arp_notes := [220.00, 261.50, 329.50, 440.00, 329.50, 261.50, 220.00, 164.75]
	
	for i in range(samples):
		var t := float(i) / float(SAMPLE_RATE)
		# Sub-grave contínuo sem corte
		var sub := sin(TAU * 55.00 * t) * (0.6 + sin(TAU * 1.0 * t) * 0.4)
		
		var pad := 0.0
		for f in pad_freqs:
			pad += sin(TAU * f * t) * 0.25
		
		var step_idx := int((t / duration) * 8.0) % 8
		var step_t := fmod(t, duration / 8.0)
		var env := sin((step_t / (duration / 8.0)) * PI) * exp(- step_t * 4.5)
		var arp := sin(TAU * arp_notes[step_idx] * t) * env
		
		var mix := (sub * 0.35 + pad * 0.45 + arp * 0.35) * 17000.0
		data.encode_s16(i * 2, int(clampf(mix, -32000.0, 32000.0)))
	
	return _make_stream_16(data, true)


# Andar 3: Ruínas Abissais Tensa (Ritmo acentuado, arpejo rápido, pulso de perigo)
func _synth_floor_3_track() -> AudioStreamWAV:
	var duration := 4.0
	var samples := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	var arp_notes := [146.75, 174.50, 220.00, 293.75, 174.50, 220.00, 293.75, 349.25, 220.00, 293.75, 349.25, 440.00, 293.75, 220.00, 174.50, 146.75]
	
	for i in range(samples):
		var t := float(i) / float(SAMPLE_RATE)
		# Batimento cardíaco grave
		var hb_cycle := fmod(t, 1.0)
		var pulse1 := sin(TAU * 50.00 * hb_cycle) * exp(- hb_cycle * 16.0)
		var hb2 := clampf(hb_cycle - 0.22, 0.0, 1.0)
		var pulse2 := sin(TAU * 46.00 * hb2) * exp(- hb2 * 18.0) * (1.0 if hb_cycle >= 0.22 else 0.0)
		var heartbeat := pulse1 * 0.65 + pulse2 * 0.5
		
		var drone := (sin(TAU * 73.50 * t) + sin(TAU * 110.00 * t) * 0.5) * (0.8 + sin(TAU * 2.0 * t) * 0.2)
		
		var step_idx := int((t / duration) * 16.0) % 16
		var step_t := fmod(t, duration / 16.0)
		var env := sin((step_t / (duration / 16.0)) * PI) * exp(- step_t * 6.5)
		var arp := sin(TAU * arp_notes[step_idx] * t) * env
		
		var mix := (heartbeat * 0.55 + drone * 0.35 + arp * 0.4) * 18500.0
		data.encode_s16(i * 2, int(clampf(mix, -32000.0, 32000.0)))
	
	return _make_stream_16(data, true)


# Andar 4: O Despenhadeiro Corrompido (Rápida, Dinâmica, Eletrizante, Marcha Sombria em 170 BPM)
func _synth_floor_4_track() -> AudioStreamWAV:
	var duration := 4.0
	var samples := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	# Sequência rápida de baixo de 16 semicolcheias em Dó/Ré menor
	var bass_fast := [73.50, 73.50, 87.25, 98.00, 73.50, 87.25, 98.00, 110.00, 73.50, 98.00, 110.00, 130.75, 98.00, 87.25, 73.50, 65.50]
	var lead_fast := [146.75, 220.00, 174.50, 261.50, 146.75, 220.00, 196.00, 293.75, 174.50, 261.50, 220.00, 349.25, 220.00, 196.00, 174.50, 146.75]
	
	for i in range(samples):
		var t := float(i) / float(SAMPLE_RATE)
		# Bateria rápida e enérgica (Kick a cada 0.25s, Snare nos tempos pares)
		var beat_t := fmod(t, 0.25)
		var kick := sin(TAU * lerpf(110.0, 45.0, beat_t / 0.25) * beat_t) * exp(- beat_t * 22.0)
		
		var snare_t := fmod(t + 0.25, 0.5)
		var snare := ((randf() * 2.0 - 1.0) * 0.35 + sin(TAU * 180.0 * snare_t) * 0.4) * exp(- snare_t * 18.0)
		
		# Baixo rápido e pulsante (16 notas em 4s)
		var step_idx := int((t / duration) * 16.0) % 16
		var step_t := fmod(t, duration / 16.0)
		var env := sin((step_t / (duration / 16.0)) * PI) * exp(- step_t * 7.0)
		
		var bass := (sin(TAU * bass_fast[step_idx] * t) + sin(TAU * bass_fast[step_idx] * 2.0 * t) * 0.3) * env
		var lead := sin(TAU * lead_fast[step_idx] * t) * env * 0.6
		
		# Pad sombrio contínuo
		var pad := (sin(TAU * 146.75 * t) + sin(TAU * 174.50 * t)) * 0.18
		
		var mix := (kick * 0.5 + snare * 0.35 + bass * 0.5 + lead * 0.35 + pad * 0.2) * 19000.0
		data.encode_s16(i * 2, int(clampf(mix, -32000.0, 32000.0)))
	
	return _make_stream_16(data, true)


# Andar 5: Santuário Celestial Sagrado (Harmonia límpida, harpa serena em frequências aveludadas)
func _synth_floor_5_track() -> AudioStreamWAV:
	var duration := 4.0
	var samples := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	var chord_f5 := [174.50, 220.00, 261.50, 329.50] # F major 7
	var harp_notes := [329.50, 392.00, 440.00, 523.25, 440.00, 392.00, 329.50, 261.50]
	
	for i in range(samples):
		var t := float(i) / float(SAMPLE_RATE)
		# Pad celestial aveludado e relaxante
		var pad := 0.0
		for f in chord_f5:
			pad += sin(TAU * f * t) * 0.25
		
		# Harpa serena dedilhada
		var step_idx := int((t / duration) * 8.0) % 8
		var step_t := fmod(t, duration / 8.0)
		var harp_env := sin((step_t / (duration / 8.0)) * PI) * exp(- step_t * 4.0)
		var harp_f: float = harp_notes[step_idx]
		var harp := sin(TAU * harp_f * t) * harp_env
		
		var breath := 0.9 + sin(TAU * 0.25 * t) * 0.1
		var mix := (pad * 0.6 + harp * 0.4) * breath * 17000.0
		data.encode_s16(i * 2, int(clampf(mix, -32000.0, 32000.0)))
	
	return _make_stream_16(data, true)


# Menu Principal: Canção Nostálgica do Guerreiro (Melancólica, suave, dedilhado de alaúde/harpa sem fadiga)
func _synth_menu_track() -> AudioStreamWAV:
	var duration := 4.0
	var samples := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	# Dedilhado melancólico em Lá menor (A3, C4, E4, D4, C4, B3, A3, E3)
	var lute_melody := [220.00, 261.50, 329.50, 293.75, 261.50, 246.75, 220.00, 164.75]
	var pad_chord := [110.00, 164.75, 220.00] # A2, E3, A3
	
	for i in range(samples):
		var t := float(i) / float(SAMPLE_RATE)
		# Pad aveludado e suave de fundo
		var pad := 0.0
		for f in pad_chord:
			pad += sin(TAU * f * t) * 0.18
		
		# Dedilhado melancólico com envelope de corda dedilhada suave
		var step_idx := int((t / duration) * 8.0) % 8
		var step_t := fmod(t, duration / 8.0)
		var env := sin((step_t / (duration / 8.0)) * PI) * exp(- step_t * 3.8)
		var note_f: float = lute_melody[step_idx]
		var lute := (sin(TAU * note_f * t) + sin(TAU * note_f * 2.0 * t) * 0.15) * env
		
		# Baixo acústico quente
		var bass := sin(TAU * 55.00 * t) * 0.25
		
		var breath := 0.9 + sin(TAU * 0.25 * t) * 0.1
		var mix := (pad * 0.4 + lute * 0.45 + bass * 0.25) * breath * 16500.0
		data.encode_s16(i * 2, int(clampf(mix, -32000.0, 32000.0)))
	
	return _make_stream_16(data, true)


# Vitória: A Canção da Vitória (Orquestral aveludada, polifonia contínua, zero fadiga e sem cliques)
func _synth_victory_track() -> AudioStreamWAV:
	var duration := 4.0
	var samples := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	# Pad harmônico puro em Dó Maior (C3, G3, C4, E4)
	var base_chord := [130.75, 196.00, 261.50, 329.50]
	# Arpejo melódico solene de 8 notas em registro médio reconfortante
	var melody := [261.50, 329.50, 392.00, 440.00, 392.00, 329.50, 293.75, 261.50]
	
	for i in range(samples):
		var t := float(i) / float(SAMPLE_RATE)
		# Pad contínuo sem descontinuidade
		var pad := 0.0
		for f in base_chord:
			pad += sin(TAU * f * t) * 0.25
		
		# Dedilhado suave com envelope de sino suave
		var step_idx := int((t / duration) * 8.0) % 8
		var step_t := fmod(t, duration / 8.0)
		var env := sin((step_t / (duration / 8.0)) * PI) * exp(- step_t * 3.5)
		var mel_f: float = melody[step_idx]
		var mel := (sin(TAU * mel_f * t) + sin(TAU * mel_f * 2.0 * t) * 0.1) * env
		
		# Baixo nobre contínuo (C2 = 65.5 Hz)
		var bass := sin(TAU * 65.50 * t) * 0.3
		
		var breath := 0.9 + sin(TAU * 0.25 * t) * 0.1
		var mix := (pad * 0.5 + mel * 0.35 + bass * 0.25) * breath * 16500.0
		data.encode_s16(i * 2, int(clampf(mix, -32000.0, 32000.0)))
	
	return _make_stream_16(data, true)


# Tragédia / Morte da Princesa: Réquiem Fúnebre Melancólico com Melodia Suave
func _synth_tragedy_track() -> AudioStreamWAV:
	var duration := 4.0
	var samples := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	var sad_notes := [293.75, 261.50, 220.00, 196.00]
	var sad_bass := [73.50, 110.00, 130.75]
	
	for i in range(samples):
		var t := float(i) / float(SAMPLE_RATE)
		var bell_t := fmod(t, 2.0)
		var bell := (sin(TAU * 110.00 * t) * 0.6 + sin(TAU * 164.75 * t) * 0.35) * exp(- bell_t * 2.2)
		
		var cello := 0.0
		for f in sad_bass:
			cello += sin(TAU * f * t) * 0.3
		
		var step_idx := int((t / duration) * 4.0) % 4
		var step_t := fmod(t, duration / 4.0)
		var lament_env := sin((step_t / (duration / 4.0)) * PI) * exp(- step_t * 2.5)
		var lament := sin(TAU * sad_notes[step_idx] * t) * lament_env
		
		var mix := (bell * 0.45 + cello * 0.45 + lament * 0.4) * 18500.0
		data.encode_s16(i * 2, int(clampf(mix, -32000.0, 32000.0)))
	
	return _make_stream_16(data, true)


# --- EFEITOS SONOROS (SFX) ---

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
	return _make_stream_16(data, false)


func _gen_ladder_climb() -> AudioStreamWAV:
	var duration := 0.08
	var samples := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t := float(i) / float(SAMPLE_RATE)
		var progress := t / duration
		var env := pow(1.0 - progress, 2.5)
		var wood := sin(TAU * 260.0 * t) * 0.65 + sin(TAU * 520.0 * t) * 0.35
		var friction := (randf() * 2.0 - 1.0) * 0.2
		var val := (wood + friction) * env * 16000.0
		data.encode_s16(i * 2, int(clampf(val, -32000.0, 32000.0)))
	return _make_stream_16(data, false)


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
	return _make_stream_16(data, false)


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
	return _make_stream_16(data, false)


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
	return _make_stream_16(data, false)


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
	return _make_stream_16(data, false)


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
	return _make_stream_16(data, false)


# Grito de morte do Guerreiro ao ser abatido em combate
func _gen_player_death_scream() -> AudioStreamWAV:
	var duration := 0.65
	var samples := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t := float(i) / float(SAMPLE_RATE)
		var progress := t / duration
		var env := sin(progress * PI * 0.5) * exp(- progress * 3.0)
		var formant1 := sin(TAU * lerpf(280.0, 110.0, pow(progress, 1.2)) * t) * 0.6
		var formant2 := sin(TAU * lerpf(560.0, 220.0, pow(progress, 1.2)) * t) * 0.4
		var rasp := (randf() * 2.0 - 1.0) * 0.25 * env
		var val := (formant1 + formant2 + rasp) * env * 24000.0
		data.encode_s16(i * 2, int(clampf(val, -32000.0, 32000.0)))
	return _make_stream_16(data, false)


# Grito de queda no abismo com efeito de afastamento e Doppler ("Aaaaaaaahhh...")
func _gen_fall_death_scream() -> AudioStreamWAV:
	var duration := 1.2
	var samples := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t := float(i) / float(SAMPLE_RATE)
		var progress := t / duration
		# Volume decai à medida que o guerreiro se afasta no fosso
		var distance_vol := pow(1.0 - progress, 1.8)
		var pitch_drop := lerpf(440.0, 90.0, pow(progress, 0.7))
		var scream := sin(TAU * pitch_drop * t) * 0.7 + sin(TAU * (pitch_drop * 1.5) * t) * 0.3
		var echo_delay := sin(TAU * 8.0 * t) * 0.15
		var val := (scream + echo_delay) * distance_vol * 26000.0
		data.encode_s16(i * 2, int(clampf(val, -32000.0, 32000.0)))
	return _make_stream_16(data, false)


# Grito sombrio / wail do Arqueiro corrompido ao ser derrotado
func _gen_enemy_death_scream() -> AudioStreamWAV:
	var duration := 0.55
	var samples := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t := float(i) / float(SAMPLE_RATE)
		var progress := t / duration
		var env := exp(- progress * 3.5)
		var shriek := sin(TAU * lerpf(680.0, 160.0, pow(progress, 0.8)) * t) * 0.55
		var hollow := sin(TAU * lerpf(340.0, 80.0, pow(progress, 0.8)) * t) * 0.45
		var noise := (randf() * 2.0 - 1.0) * 0.3 * env
		var val := (shriek + hollow + noise) * env * 23000.0
		data.encode_s16(i * 2, int(clampf(val, -32000.0, 32000.0)))
	return _make_stream_16(data, false)


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
	return _make_stream_16(data, false)


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
	return _make_stream_16(data, false)


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
	return _make_stream_16(data, false)


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
	return _make_stream_16(data, false)


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
	return _make_stream_16(data, false)


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
	return _make_stream_16(data, false)


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
	return _make_stream_16(data, false)


func _gen_princess_hit() -> AudioStreamWAV:
	var duration := 0.7
	var samples := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t := float(i) / float(SAMPLE_RATE)
		var env := exp(- (t / duration) * 3.0)
		var glass := (sin(TAU * 1864.66 * t) * 0.4 + sin(TAU * 2637.02 * t) * 0.3 + (randf() * 2.0 - 1.0) * 0.3)
		var gasp := sin(TAU * lerpf(520.0, 180.0, t / duration) * t) * 0.6
		var val := (glass + gasp) * env * 24000.0
		data.encode_s16(i * 2, int(clampf(val, -32000.0, 32000.0)))
	return _make_stream_16(data, false)


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
	return _make_stream_16(data, false)


func _make_stream_16(data: PackedByteArray, loop: bool = false) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = data
	if loop:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = data.size() / 2
	return stream
