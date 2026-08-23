extends StaticBody2D

@export var is_active_by_default := false
@export var target_offset := Vector2(0, 0)
@export var move_duration := 0.8
@export var fade_in_on_activate := false

const COLOR_CRYSTAL_ACTIVE := Color(0.25, 0.92, 0.95, 0.95)
const COLOR_CRYSTAL_INACTIVE := Color(0.35, 0.3, 0.45, 0.35)
const COLOR_VEIN_ACTIVE := Color(0.25, 0.95, 0.85, 0.65)
const COLOR_VEIN_INACTIVE := Color(0.2, 0.16, 0.28, 0.2)

var start_pos: Vector2
var is_active := false
var tween: Tween = null
var time_passed := 0.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D if has_node("CollisionShape2D") else null
@onready var visual: Node2D = $Visual if has_node("Visual") else null
@onready var mana_vein: Polygon2D = $Visual/ManaVein if has_node("Visual/ManaVein") else null
@onready var crystals_group: Node2D = $Visual/Crystals if has_node("Visual/Crystals") else null
@onready var floating_shards: Node2D = $Visual/FloatingShards if has_node("Visual/FloatingShards") else null
@onready var underglow: Polygon2D = $Visual/EtherealUnderglow if has_node("Visual/EtherealUnderglow") else null


func _ready() -> void:
	start_pos = position

	if is_active_by_default:
		is_active = true
		position = start_pos + target_offset
		if collision_shape:
			collision_shape.set_deferred("disabled", false)
		_set_active_visuals(true)
		if visual:
			visual.modulate.a = 1.0
	else:
		is_active = false
		_set_active_visuals(false)
		if fade_in_on_activate:
			if collision_shape:
				collision_shape.set_deferred("disabled", true)
			if visual:
				visual.modulate.a = 0.0


func _process(delta: float) -> void:
	if not is_active:
		return

	time_passed += delta
	if underglow != null:
		underglow.modulate.a = 0.6 + sin(time_passed * 3.0) * 0.35

	if crystals_group != null:
		var idx := 0
		for c in crystals_group.get_children():
			if c is Node2D:
				var gem = c.get_node_or_null("Gem")
				if gem is Polygon2D:
					gem.scale = Vector2.ONE * (1.0 + sin(time_passed * 3.0 + idx * 0.8) * 0.1)
			idx += 1

	if floating_shards != null:
		var s_idx := 0
		var shard_y_bases = [24.0, 28.0, 27.0, 22.0]
		for s in floating_shards.get_children():
			if s is Node2D:
				var base_y = shard_y_bases[s_idx % shard_y_bases.size()]
				s.position.y = base_y + sin(time_passed * 2.2 + s_idx * 1.3) * 2.5
			s_idx += 1


func _set_active_visuals(active: bool) -> void:
	if mana_vein:
		mana_vein.color = COLOR_VEIN_ACTIVE if active else COLOR_VEIN_INACTIVE
	if crystals_group:
		for c in crystals_group.get_children():
			if c is Node2D:
				var gem = c.get_node_or_null("Gem")
				if gem is Polygon2D:
					gem.color = COLOR_CRYSTAL_ACTIVE if active else COLOR_CRYSTAL_INACTIVE
				var core = c.get_node_or_null("Core")
				if core is Polygon2D:
					core.visible = active
	if floating_shards:
		floating_shards.visible = active
	if underglow:
		underglow.visible = active


func activate() -> void:
	open()


func open() -> void:
	if is_active:
		return
	is_active = true

	if tween and tween.is_valid():
		tween.kill()
	tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	if target_offset != Vector2.ZERO:
		tween.tween_property(self, "position", start_pos + target_offset, move_duration)

	_set_active_visuals(true)

	if fade_in_on_activate:
		if collision_shape:
			collision_shape.set_deferred("disabled", false)
		if visual:
			tween.tween_property(visual, "modulate:a", 1.0, move_duration)


func close() -> void:
	if not is_active:
		return
	is_active = false

	if tween and tween.is_valid():
		tween.kill()
	tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	if target_offset != Vector2.ZERO:
		tween.tween_property(self, "position", start_pos, move_duration)

	_set_active_visuals(false)

	if fade_in_on_activate:
		if visual:
			tween.tween_property(visual, "modulate:a", 0.0, move_duration)
		if collision_shape:
			collision_shape.set_deferred("disabled", true)
