extends Node2D

const NoteScene := preload("res://scenes/note.tscn");


func _on_conductor_measure(position: int) -> void:
	var chord = $ChordGenerator.advance();
	$MusicPlayer.play_chord(chord);
	spawnNote(chord);


func spawnNote(chord: int) -> void:
	var noteInstance = NoteScene.instantiate();
	noteInstance.initialize(randi() % 4, chord);
	add_child(noteInstance);
