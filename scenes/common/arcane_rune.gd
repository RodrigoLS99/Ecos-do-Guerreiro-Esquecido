extends Node2D

@export var pulse_speed: float = 2.0

var _time_offset: float = 0.0

@onready var glow: Polygon2D = $Glow
@onready var crystal_main: Polygon2D = $CrystalMain
@onready var crystal_main_hi: Polygon2D = $CrystalMainHi
@onready var crystal_sub: Polygon2D = $CrystalSub
@onready var crystal_sub_hi: Polygon2D = $CrystalSubHi
@onready var crystal_shard: Polygon2D = $CrystalShard


func _ready() -> void:
	_time_offset = randf() * 100.0


func _process(_delta: float) -> void:
	var t := Time.get_ticks_msec() * 0.001 * pulse_speed + _time_offset
	var pulse := (sin(t) + 1.0) * 0.5

	if glow != null:
		var s := 0.9 + pulse * 0.25
		glow.scale = Vector2(s, s)
		glow.modulate.a = 0.35 + pulse * 0.4

	var alpha := 0.8 + pulse * 0.2
	if crystal_main != null:
		crystal_main.modulate.a = alpha
	if crystal_main_hi != null:
		crystal_main_hi.modulate.a = alpha
	if crystal_sub != null:
		crystal_sub.modulate.a = alpha
	if crystal_sub_hi != null:
		crystal_sub_hi.modulate.a = alpha
	if crystal_shard != null:
		crystal_shard.modulate.a = alpha
