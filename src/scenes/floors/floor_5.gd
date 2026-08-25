extends Node2D

@onready var artifact: Area2D = $Artifact if has_node("Artifact") else null
@onready var princess: Area2D = $Princess if has_node("Princess") else null
@onready var gate_princess: StaticBody2D = $Gate_Princess if has_node("Gate_Princess") else null
@onready var floor_exit: Area2D = $FloorExit if has_node("FloorExit") else null
@onready var banner: CanvasLayer = $NarrativeBanner if has_node("NarrativeBanner") else null
@onready var banner_label: Label = $NarrativeBanner/Panel/Label if has_node("NarrativeBanner/Panel/Label") else null


func _ready() -> void:
	if artifact:
		artifact.collected.connect(_on_artifact_collected)
	if princess:
		princess.rescued.connect(_on_princess_rescued)
	if floor_exit:
		floor_exit.visible = false
		if floor_exit.has_node("CollisionShape2D"):
			floor_exit.get_node("CollisionShape2D").set_deferred("disabled", true)
	if banner:
		banner.visible = false


func _on_artifact_collected() -> void:
	show_message("Artefato Sagrado Recuperado! O selo da câmara se abriu.")
	if gate_princess and gate_princess.has_method("open"):
		gate_princess.open()


func _on_princess_rescued() -> void:
	show_message("A Princesa foi libertada! O portal da vitória está aberto.")
	if floor_exit:
		floor_exit.visible = true
		if floor_exit.has_node("CollisionShape2D"):
			floor_exit.get_node("CollisionShape2D").set_deferred("disabled", false)
		
		# Glow / pulse effect
		var tw := create_tween().set_loops()
		tw.tween_property(floor_exit, "modulate", Color(1.3, 1.3, 1.5, 1.0), 0.6)
		tw.tween_property(floor_exit, "modulate", Color(0.8, 0.9, 1.0, 1.0), 0.6)


func show_message(text: String) -> void:
	if banner == null or banner_label == null:
		return
	banner_label.text = text
	banner.visible = true
	var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	banner.offset = Vector2(0, -50)
	tw.tween_property(banner, "offset", Vector2.ZERO, 0.4)
	tw.tween_interval(3.5)
	tw.tween_property(banner, "offset", Vector2(0, -60), 0.4)
	tw.chain().tween_callback(func(): banner.visible = false)
