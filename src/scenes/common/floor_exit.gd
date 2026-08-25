extends Area2D

@onready var aura: Polygon2D = $Visual/AuraGlow if has_node("Visual/AuraGlow") else null
@onready var outer_vortex: Polygon2D = $Visual/OuterVortex if has_node("Visual/OuterVortex") else null
@onready var inner_vortex: Polygon2D = $Visual/InnerVortex if has_node("Visual/InnerVortex") else null
@onready var rift_core: Polygon2D = $Visual/RiftCore if has_node("Visual/RiftCore") else null
@onready var motes: Node2D = $Visual/OrbitalMotes if has_node("Visual/OrbitalMotes") else null

var _time_offset: float = 0.0


func _ready() -> void:
	_time_offset = randf() * 50.0
	body_entered.connect(_on_body_entered)


func _process(_delta: float) -> void:
	if not visible:
		return
	var t := Time.get_ticks_msec() * 0.003 + _time_offset
	var pulse := sin(t * 3.0) * 0.5 + 0.5
	
	if aura != null:
		var s := 1.0 + pulse * 0.18
		aura.scale = Vector2(s, s)
		aura.modulate.a = 0.65 + pulse * 0.35
	
	if outer_vortex != null:
		outer_vortex.rotation = t * 1.2
		var s_out := 1.0 + sin(t * 2.5) * 0.08
		outer_vortex.scale = Vector2(s_out, 1.0 / s_out)
	
	if inner_vortex != null:
		inner_vortex.rotation = -t * 1.8
		var s_in := 1.0 + cos(t * 3.2) * 0.1
		inner_vortex.scale = Vector2(s_in, s_in)
	
	if rift_core != null:
		var s_core := 1.0 + pulse * 0.22
		rift_core.scale = Vector2(s_core, s_core)
		rift_core.modulate.a = 0.85 + pulse * 0.15
	
	if motes != null:
		motes.rotation = t * 0.8


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		GameState.go_to_next_floor()
