extends Node2D

const NoteScene := preload("res://scenes/note.tscn");

var currentChord: int = 0
var currentSection: int = 0
var currentIntensity: float = 0.2

func _on_conductor_measure(measurePosition: int) -> void:
	if measurePosition == 1:
		currentChord = $ChordGenerator.advance();
		$ChordGenerator.maybeRefresh();
		$StructuralEngine.advance_bar();
		$MusicPlayer.set_bar($StructuralEngine.barsInSection, $StructuralEngine.is_last_bar());

	$MusicPlayer.play_on_beat(currentChord, measurePosition);

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
	$MusicPlayer.set_section(section, intensity, $StructuralEngine.cycleCount)
	print(currentSection, " ", currentIntensity);

func _on_conductor_subdivision(conductorPosition: Variant) -> void:
	$MusicPlayer.play_on_subdivision(conductorPosition, currentChord)

func _on_music_player_chord_played() -> void:
	if $OptionMenuNode2D/GameplayHandler.spawnNoteOnRhodes:
		spawnNote(currentChord)

func _on_music_player_drum_clap_played() -> void:
	if $OptionMenuNode2D/GameplayHandler.spawnNoteOnDrumClap:
		spawnNote(currentChord)

func _on_music_player_drum_hi_hat_closed_played() -> void:
	if $OptionMenuNode2D/GameplayHandler.spawnNoteOnDrumHiHatClose:
		spawnNote(currentChord)

func _on_music_player_drum_hi_hat_open_played() -> void:
	if $OptionMenuNode2D/GameplayHandler.spawnNoteOnDrumHiHatOpen:
		spawnNote(currentChord)

func _on_music_player_drum_kick_played() -> void:
	if $OptionMenuNode2D/GameplayHandler.spawnNoteOnDrumKick:
		spawnNote(currentChord)
