extends Area2D

@export_multiline var message: String = "✦ Mensagem Tutorial ✦"
@export var display_duration: float = 3.5
@export var auto_trigger_on_start := false

var has_triggered := false

@onready var banner: CanvasLayer = $Banner if has_node("Banner") else null
@onready var label: Label = $Banner/Panel/Label if has_node("Banner/Panel/Label") else null


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if banner:
		banner.visible = false
	if SettingsManager:
		SettingsManager.controls_changed.connect(_on_controls_changed)
	if auto_trigger_on_start:
		call_deferred(&"trigger_message")


func _on_body_entered(body: Node2D) -> void:
	if has_triggered:
		return
	if body.is_in_group(&"player"):
		trigger_message()


func trigger_message() -> void:
	if has_triggered or banner == null or label == null:
		return
	has_triggered = true
	label.text = get_formatted_text()
	banner.visible = true
	
	var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	banner.offset = Vector2(0, -60)
	tw.tween_property(banner, "offset", Vector2.ZERO, 0.4)
	tw.tween_interval(display_duration)
	tw.tween_property(banner, "offset", Vector2(0, -60), 0.4)
	tw.chain().tween_callback(func(): banner.visible = false)


func get_formatted_text() -> String:
	if SettingsManager:
		return SettingsManager.format_prompt(message)
	return message


func _on_controls_changed() -> void:
	if banner and banner.visible and label:
		label.text = get_formatted_text()
