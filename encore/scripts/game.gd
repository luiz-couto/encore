extends Node2D

const NoteScene := preload("res://scenes/note.tscn");

var currentChord: int = 0
var currentSection: int = 0
var currentIntensity: float = 0.2

var avoidDoubleNotesThreshold: float = 150

var paused: bool = false
var options: Array = []
var hitStreak: int = 0

func _on_conductor_measure(measurePosition: int) -> void:
	if measurePosition == 1:
		currentChord = $ChordGenerator.advance();
		$ChordGenerator.maybeRefresh();
		$StructuralEngine.advance_bar();
		$MusicPlayer.set_bar($StructuralEngine.barsInSection, $StructuralEngine.is_last_bar());

	$MusicPlayer.play_on_beat(currentChord, measurePosition);

func spawnNote(chord: int, sound_id: int = -1) -> void:
	if paused:
		return
	var gameplayHandler = $OptionMenuNode2D/GameplayHandler
	_spawn_single_note(chord, sound_id)
	if randf() < gameplayHandler.spawnTripleNotesProb:
		_spawn_single_note(chord)
		_spawn_single_note(chord)
	elif randf() < gameplayHandler.spawnDoubleNotesProb:
		_spawn_single_note(chord)

func _spawn_single_note(chord: int, sound_id: int = -1) -> void:
	var lane = choose_lane()
	if lane == -1:
		return
	var noteInstance = NoteScene.instantiate()
	noteInstance.scoreEvent.connect(_on_score_event)
	noteInstance.missEvent.connect(_on_note_missed)
	var seconds_per_measure = $Conductor.secondsPerBeat * $Conductor.measures
	noteInstance.initialize(lane, chord, seconds_per_measure, sound_id)
	add_child(noteInstance)

func choose_lane() -> int:
	var gameplayHandler = $OptionMenuNode2D/GameplayHandler
	var occupied: Array = []
	for note in get_tree().get_nodes_in_group("notes"):
		if note.position.y < avoidDoubleNotesThreshold:
			occupied.append(note.lane)
	var available = [0, 1, 2, 3].filter(func(l): return gameplayHandler.activeLanes[l] and l not in occupied)
	var chosen_lane = available[randi() % available.size()] if available.size() > 0 else -1
	return chosen_lane

func _on_score_event(scorePoints: int, _chord_idx: int, sound_id: int) -> void:
	$MusicPlayer.register_hit(sound_id)
	hitStreak += 1
	var gameplayHandler = $OptionMenuNode2D/GameplayHandler
	$ScoreNode2D.score += int(scorePoints * gameplayHandler.scoreMultiplier * gameplayHandler.comboMultiplier * hitStreak)
	if $ScoreNode2D.score % 1000 == 0:
		pass
		#paused = true
		#_show_options_menu()

func _on_note_missed() -> void:
	hitStreak = 0

func _apply_lanes_keys() -> void:
	var lanesKeys = $OptionMenuNode2D/GameplayHandler.lanesKeys
	var buttons = [$Button, $Button2, $Button3, $Button4]
	for i in 4:
		if lanesKeys[i] != "":
			buttons[i].input = lanesKeys[i]

func _show_options_menu():
	options = $OptionMenuNode2D/GameplayHandler.getOptions()
	$OptionMenuNode2D.set_option_1_label(options[0].label)
	$OptionMenuNode2D.set_option_2_label(options[1].label)
	$OptionMenuNode2D.set_option_3_label(options[2].label)
	$DimOverlay.visible = true
	$OptionMenuNode2D.visible = true

func _hide_options_menu():
	$DimOverlay.visible = false
	$OptionMenuNode2D.visible = false

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

func _on_music_player_note_scheduled(_instrument: int, chord_idx: int, sound_id: int) -> void:
	spawnNote(chord_idx, sound_id)

func _sync_player_controlled_instruments() -> void:
	var gameplayHandler = $OptionMenuNode2D/GameplayHandler
	$MusicPlayer.set_player_controlled($MusicPlayer.Instrument.RHODES,       gameplayHandler.spawnNoteOnRhodes)
	$MusicPlayer.set_player_controlled($MusicPlayer.Instrument.CHORD_STAB,  gameplayHandler.spawnNoteOnRhodes)
	$MusicPlayer.set_player_controlled($MusicPlayer.Instrument.KICK,         gameplayHandler.spawnNoteOnDrumKick)
	$MusicPlayer.set_player_controlled($MusicPlayer.Instrument.HIHAT_CLOSED, gameplayHandler.spawnNoteOnDrumHiHatClose)
	$MusicPlayer.set_player_controlled($MusicPlayer.Instrument.HIHAT_OPEN,   gameplayHandler.spawnNoteOnDrumHiHatOpen)
	$MusicPlayer.set_player_controlled($MusicPlayer.Instrument.CLAP,         gameplayHandler.spawnNoteOnDrumClap)
	$MusicPlayer.set_player_controlled($MusicPlayer.Instrument.CONGA_OPEN,   gameplayHandler.spawnNoteOnCongaOpen)
	$MusicPlayer.set_player_controlled($MusicPlayer.Instrument.CONGA_SLAP,   gameplayHandler.spawnNoteOnCongaSlap)


func _on_option_selected(option_index: int) -> void:
	options[option_index].action.call()
	$Conductor.bpm = $OptionMenuNode2D/GameplayHandler.bpm
	_apply_lanes_keys()
	_sync_player_controlled_instruments()
	_hide_options_menu()
	paused = false

func _on_option_1_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton && event.pressed:
		_on_option_selected(0)

func _on_option_2_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton && event.pressed:
		_on_option_selected(1)

func _on_option_3_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton && event.pressed:
		_on_option_selected(2)


func _on_music_player_genre_changed(bpm: int) -> void:
	$OptionMenuNode2D/GameplayHandler.bpm = bpm
	$Conductor.bpm = bpm
	$ChordGenerator.set_genre($MusicPlayer.currentGenre)

func _on_ready() -> void:
	$Conductor.bpm = $OptionMenuNode2D/GameplayHandler.bpm
	_sync_player_controlled_instruments()
