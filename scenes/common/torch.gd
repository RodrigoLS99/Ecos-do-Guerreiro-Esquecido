extends Node2D

@export var base_scale: float = 1.0
@export var glow_color: Color = Color(1.0, 0.72, 0.28, 0.22)
@export var flame_outer_color: Color = Color(1.0, 0.45, 0.1, 0.95)
@export var flame_inner_color: Color = Color(1.0, 0.88, 0.4, 0.98)

var _time_offset: float = 0.0

@onready var glow: Polygon2D = $TorchGlow
@onready var flame_outer: Polygon2D = $TorchFlame/OuterFlame
@onready var flame_inner: Polygon2D = $TorchFlame/InnerFlame
@onready var flame_root: Node2D = $TorchFlame


func _ready() -> void:
	_time_offset = randf() * 100.0
	if glow != null:
		glow.color = glow_color
	if flame_outer != null:
		flame_outer.color = flame_outer_color
	if flame_inner != null:
		flame_inner.color = flame_inner_color


func _process(_delta: float) -> void:
	var t := Time.get_ticks_msec() * 0.005 + _time_offset
	var flicker := sin(t * 2.1) * 0.5 + sin(t * 4.7) * 0.3 + sin(t * 9.3) * 0.2
	if glow != null:
		var s := base_scale * (1.0 + flicker * 0.14)
		glow.scale = Vector2(s, s)
		glow.modulate.a = 0.85 + flicker * 0.2
	if flame_root != null:
		flame_root.scale = Vector2(1.0 + flicker * 0.1, 1.0 + flicker * 0.18)
