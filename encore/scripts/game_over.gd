extends Node2D

const HOVER_SCALE_MULTIPLIER: float = 1.15
const HOVER_BRIGHTNESS: float = 1.4
const HOVER_DURATION: float = 0.1

var _backToMenuTween: Tween = null
var _originalScale: Vector2

func _ready() -> void:
	get_viewport().physics_object_picking = true
	_originalScale = $BackToMenuIcon.scale

func show_results(score: int, time_seconds: float, stage: int) -> void:
	$FinalScoreLabel.text = str(score)
	var minutes = int(time_seconds / 60)
	var seconds = int(time_seconds) % 60
	$FinalTimeLabel.text = "%02d:%02d" % [minutes, seconds]
	$StageLabel.text = "STAGE: " + str(stage)
	$Timer.start()

func _process(_delta: float) -> void:
	pass

func _on_back_to_menu_area_2d_mouse_entered() -> void:
	DisplayServer.cursor_set_shape(DisplayServer.CURSOR_POINTING_HAND)
	if _backToMenuTween:
		_backToMenuTween.kill()
	_backToMenuTween = create_tween().set_parallel(true)
	_backToMenuTween.tween_property($BackToMenuIcon, "scale", _originalScale * HOVER_SCALE_MULTIPLIER, HOVER_DURATION)
	_backToMenuTween.tween_property($BackToMenuIcon, "modulate", Color(HOVER_BRIGHTNESS, HOVER_BRIGHTNESS, HOVER_BRIGHTNESS), HOVER_DURATION)

func _on_back_to_menu_area_2d_mouse_exited() -> void:
	DisplayServer.cursor_set_shape(DisplayServer.CURSOR_ARROW)
	if _backToMenuTween:
		_backToMenuTween.kill()
	_backToMenuTween = create_tween().set_parallel(true)
	_backToMenuTween.tween_property($BackToMenuIcon, "scale", _originalScale, HOVER_DURATION)
	_backToMenuTween.tween_property($BackToMenuIcon, "modulate", Color(1.0, 1.0, 1.0), HOVER_DURATION)

func _on_back_to_menu_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		_cleanup_master_lowpass()
		get_tree().reload_current_scene()

func _cleanup_master_lowpass() -> void:
	var master_idx = AudioServer.get_bus_index("Master")
	for i in range(AudioServer.get_bus_effect_count(master_idx) - 1, -1, -1):
		if AudioServer.get_bus_effect(master_idx, i) is AudioEffectLowPassFilter:
			AudioServer.remove_bus_effect(master_idx, i)
