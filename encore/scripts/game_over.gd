extends Node2D

func show_results(score: int, time_seconds: float) -> void:
	$FinalScoreLabel.text = str(score)
	var minutes = int(time_seconds / 60)
	var seconds = int(time_seconds) % 60
	$FinalTimeLabel.text = "%02d:%02d" % [minutes, seconds]
	$Timer.start()

func _process(_delta: float) -> void:
	pass
