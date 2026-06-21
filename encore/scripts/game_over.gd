extends Node2D

var _tryAgainTween: Tween = null
var _backToMenuTween: Tween = null

const HOVER_ALPHA: float = 0.65
const HOVER_DURATION: float = 0.1

func show_results(score: int, time_seconds: float) -> void:
	$FinalScoreLabel.text = str(score)
	var minutes = int(time_seconds / 60)
	var seconds = int(time_seconds) % 60
	$FinalTimeLabel.text = "%02d:%02d" % [minutes, seconds]
	$Timer.start()

func _process(_delta: float) -> void:
	pass

func _on_try_again_area_2d_mouse_entered() -> void:
	if _tryAgainTween:
		_tryAgainTween.kill()
	_tryAgainTween = create_tween()
	_tryAgainTween.tween_property($TryAgainButton, "modulate:a", HOVER_ALPHA, HOVER_DURATION)

func _on_try_again_area_2d_mouse_exited() -> void:
	if _tryAgainTween:
		_tryAgainTween.kill()
	_tryAgainTween = create_tween()
	_tryAgainTween.tween_property($TryAgainButton, "modulate:a", 1.0, HOVER_DURATION)

func _on_try_again_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		_cleanup_master_lowpass()
		get_tree().reload_current_scene()

func _on_back_to_menu_area_2d_mouse_entered() -> void:
	if _backToMenuTween:
		_backToMenuTween.kill()
	_backToMenuTween = create_tween()
	_backToMenuTween.tween_property($BackToMenuButton, "modulate:a", HOVER_ALPHA, HOVER_DURATION)

func _on_back_to_menu_area_2d_mouse_exited() -> void:
	if _backToMenuTween:
		_backToMenuTween.kill()
	_backToMenuTween = create_tween()
	_backToMenuTween.tween_property($BackToMenuButton, "modulate:a", 1.0, HOVER_DURATION)

func _on_back_to_menu_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		pass

func _cleanup_master_lowpass() -> void:
	var master_idx = AudioServer.get_bus_index("Master")
	for i in range(AudioServer.get_bus_effect_count(master_idx) - 1, -1, -1):
		if AudioServer.get_bus_effect(master_idx, i) is AudioEffectLowPassFilter:
			AudioServer.remove_bus_effect(master_idx, i)
