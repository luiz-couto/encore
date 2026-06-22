extends Node2D

signal started()

const HOVER_SCALE_MULTIPLIER: float = 1.15
const HOVER_BRIGHTNESS: float = 1.4
const HOVER_DURATION: float = 0.1

var _startTween: Tween = null
var _exitTween: Tween = null
var _startOriginalScale: Vector2
var _exitOriginalScale: Vector2

func _ready() -> void:
	_startOriginalScale = $StartIcon3.scale
	_exitOriginalScale = $ExitButton2.scale

func _process(_delta: float) -> void:
	pass

func _on_start_icon_area_2d_mouse_entered() -> void:
	DisplayServer.cursor_set_shape(DisplayServer.CURSOR_POINTING_HAND)
	if _startTween:
		_startTween.kill()
	_startTween = create_tween().set_parallel(true)
	_startTween.tween_property($StartIcon3, "scale", _startOriginalScale * HOVER_SCALE_MULTIPLIER, HOVER_DURATION)
	_startTween.tween_property($StartIcon3, "modulate", Color(HOVER_BRIGHTNESS, HOVER_BRIGHTNESS, HOVER_BRIGHTNESS), HOVER_DURATION)

func _on_start_icon_area_2d_mouse_exited() -> void:
	DisplayServer.cursor_set_shape(DisplayServer.CURSOR_ARROW)
	if _startTween:
		_startTween.kill()
	_startTween = create_tween().set_parallel(true)
	_startTween.tween_property($StartIcon3, "scale", _startOriginalScale, HOVER_DURATION)
	_startTween.tween_property($StartIcon3, "modulate", Color(1.0, 1.0, 1.0), HOVER_DURATION)

func _on_start_icon_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		started.emit()

func _on_exit_area_2d_mouse_entered() -> void:
	DisplayServer.cursor_set_shape(DisplayServer.CURSOR_POINTING_HAND)
	if _exitTween:
		_exitTween.kill()
	_exitTween = create_tween().set_parallel(true)
	_exitTween.tween_property($ExitButton2, "scale", _exitOriginalScale * HOVER_SCALE_MULTIPLIER, HOVER_DURATION)
	_exitTween.tween_property($ExitButton2, "modulate", Color(HOVER_BRIGHTNESS, HOVER_BRIGHTNESS, HOVER_BRIGHTNESS), HOVER_DURATION)

func _on_exit_area_2d_mouse_exited() -> void:
	DisplayServer.cursor_set_shape(DisplayServer.CURSOR_ARROW)
	if _exitTween:
		_exitTween.kill()
	_exitTween = create_tween().set_parallel(true)
	_exitTween.tween_property($ExitButton2, "scale", _exitOriginalScale, HOVER_DURATION)
	_exitTween.tween_property($ExitButton2, "modulate", Color(1.0, 1.0, 1.0), HOVER_DURATION)

func _on_exit_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		get_tree().quit()
