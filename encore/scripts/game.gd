extends Node2D

const NoteScene := preload("res://scenes/note.tscn");

var currentChord: int = 0;

func _on_conductor_measure(position: int) -> void:
	if position == 1:
		currentChord = $ChordGenerator.advance();
		$MusicPlayer.play_chord(currentChord);
		$ChordGenerator.maybeRefresh();

	spawnNote(currentChord);

func spawnNote(chord: int) -> void:
	var noteInstance = NoteScene.instantiate();
	noteInstance.scoreEvent.connect(_on_score_event);
	var seconds_per_measure = $Conductor.secondsPerBeat * $Conductor.measures;
	noteInstance.initialize(randi() % 4, chord, seconds_per_measure);
	add_child(noteInstance);

func _on_score_event(scorePoints: int) -> void:
	$ScoreNode2D.score += scorePoints;

func _on_timer_timeout() -> void:
	pass # Replace with function body.
