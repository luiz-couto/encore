extends Node2D

const NoteScene := preload("res://scenes/note.tscn");

var currentChord: int = 0
var currentSection = 0
var currentIntensity: float = 0.2

func _on_conductor_measure(measurePosition: int) -> void:
	if measurePosition == 1:
		currentChord = $ChordGenerator.advance();
		$ChordGenerator.maybeRefresh();
		$StructuralEngine.advance_bar();

	$MusicPlayer.play_chord(currentChord);
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

func _on_structural_engine_section_changed(section: Variant, intensity: Variant) -> void:
	currentSection = section
	currentIntensity = intensity
	$ChordGenerator.pick_progression()
	print(currentSection, " ", currentIntensity);
