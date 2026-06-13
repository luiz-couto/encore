extends Node2D

const NoteScene := preload("res://scenes/note.tscn");


func _on_conductor_measure(position: int) -> void:
	var chord = $ChordGenerator.advance();
	$MusicPlayer.play_chord(chord);
	spawnNote(chord);

func spawnNote(chord: int) -> void:
	var noteInstance = NoteScene.instantiate();
	noteInstance.scoreEvent.connect(_on_score_event);
	var seconds_per_measure = $Conductor.secondsPerBeat * $Conductor.measures;
	noteInstance.initialize(randi() % 4, chord, seconds_per_measure);
	add_child(noteInstance);

func _on_score_event(scorePoints: int) -> void:
	$ScoreNode2D.score += scorePoints;
