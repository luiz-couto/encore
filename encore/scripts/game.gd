extends Node2D

const NoteScene := preload("res://scenes/note.tscn")
const HeartScene := preload("res://scenes/heart.tscn")

var currentChord: int = 0
var currentSection: int = 0
var currentIntensity: float = 0.2

var avoidDoubleNotesThreshold: float = 150

var paused: bool = false
var options: Array = []
var hitStreak: int = 0
var timeElapsed: float = 0.0

var _lowPassFilter: AudioEffectLowPassFilter = null
var _lowPassTween: Tween = null

const LOWPASS_CUTOFF_NORMAL: float = 20000.0
const LOWPASS_CUTOFF_PAUSED: float = 1000.0
const LOWPASS_PAUSE_DURATION: float = 0.4
const LOWPASS_UNPAUSE_DURATION: float = 0.2

func _set_paused(value: bool) -> void:
	paused = value
	if _lowPassTween:
		_lowPassTween.kill()
	_lowPassTween = create_tween()
	var target_cutoff = LOWPASS_CUTOFF_PAUSED if value else LOWPASS_CUTOFF_NORMAL
	var duration = LOWPASS_PAUSE_DURATION if value else LOWPASS_UNPAUSE_DURATION
	_lowPassTween.tween_property(_lowPassFilter, "cutoff_hz", target_cutoff, duration)

func _process(delta: float) -> void:
	if not paused:
		timeElapsed += delta

func _on_conductor_measure(measurePosition: int) -> void:
	if measurePosition == 1:
		currentChord = $ChordGenerator.advance();
		$ChordGenerator.maybeRefresh();
		if not paused:
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
	$ScoreNode2D.streak = hitStreak
	var gameplayHandler = $OptionMenuNode2D/GameplayHandler
	$ScoreNode2D.score += int(scorePoints * gameplayHandler.scoreMultiplier * gameplayHandler.comboMultiplier * hitStreak)

func _rebuild_hearts() -> void:
	var gameplayHandler = $OptionMenuNode2D/GameplayHandler
	var container = $GridContainer
	container.columns = max(1, int(container.size.x / HEART_CELL_SIZE))
	for child in container.get_children():
		child.queue_free()
	for i in gameplayHandler.numberOfLives:
		container.add_child(HeartScene.instantiate())

const SHAKE_DURATION: float = 0.3
const SHAKE_INTENSITY: float = 12.0
const SHAKE_STEPS: int = 10
const FLASH_DURATION: float = 0.35
const FLASH_ALPHA: float = 0.35
const GAME_OVER_FLASH_DURATION: float = 0.35
const GAME_OVER_FLASH_ALPHA: float = 0.6

func _on_note_missed() -> void:
	hitStreak = 0
	var gameplayHandler = $OptionMenuNode2D/GameplayHandler
	gameplayHandler.numberOfLives = max(0, gameplayHandler.numberOfLives - gameplayHandler.livesLostPerMiss)
	_rebuild_hearts()
	if gameplayHandler.numberOfLives == 0:
		_show_game_over()
		return
	_play_damage_feedback()

func _show_game_over() -> void:
	_set_paused(true)
	_set_lane_flash_visible(false)
	_play_flash(GAME_OVER_FLASH_ALPHA, GAME_OVER_FLASH_DURATION)
	$GameOver.show_results($ScoreNode2D.score, timeElapsed, $StructuralEngine.cycleCount)
	$GameOver.visible = true
	$DimOverlay.visible = true

func _show_main_menu() -> void:
	_set_paused(true)
	$DimOverlay.visible = true
	$MainMenu.visible = true

func _hide_main_menu() -> void:
	$MainMenu.visible = false
	$DimOverlay.visible = false
	_set_paused(false)


func _play_flash(alpha: float, duration: float) -> void:
	var flash = $DamageFlash
	flash.color.a = alpha
	var flash_tween = create_tween()
	flash_tween.tween_property(flash, "color:a", 0.0, duration)

func _play_damage_feedback() -> void:
	_play_flash(FLASH_ALPHA, FLASH_DURATION)
	var camera = $Camera2D
	var shake_tween = create_tween()
	shake_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	for i in SHAKE_STEPS:
		shake_tween.tween_property(camera, "offset", Vector2(960, 540) + Vector2(randf_range(-SHAKE_INTENSITY, SHAKE_INTENSITY), randf_range(-SHAKE_INTENSITY, SHAKE_INTENSITY)), SHAKE_DURATION / SHAKE_STEPS)
	shake_tween.tween_property(camera, "offset", Vector2(960, 540), 0.05)

func _apply_lanes_keys() -> void:
	var lanesKeys = $OptionMenuNode2D/GameplayHandler.lanesKeys
	var buttons = [$Button, $Button2, $Button3, $Button4]
	for i in 4:
		if lanesKeys[i] != "":
			buttons[i].input = lanesKeys[i]

func _set_lane_flash_visible(value: bool) -> void:
	for button in [$Button, $Button2, $Button3, $Button4]:
		button.laneFlash.visible = value

func _show_options_menu():
	options = $OptionMenuNode2D/GameplayHandler.getOptions()
	$OptionMenuNode2D.set_option_1_label(options[0].label)
	$OptionMenuNode2D.set_option_2_label(options[1].label)
	$OptionMenuNode2D.set_option_3_label(options[2].label)
	$DimOverlay.visible = true
	$OptionMenuNode2D.visible = true
	_set_lane_flash_visible(false)
	_set_paused(true)

func _hide_options_menu():
	$DimOverlay.visible = false
	$OptionMenuNode2D.visible = false
	_set_lane_flash_visible(true)

func _on_timer_timeout() -> void:
	pass # Replace with function body.

func _on_structural_engine_section_changed(section: Variant, intensity: Variant) -> void:
	currentSection = section
	currentIntensity = intensity
	$ChordGenerator.pick_progression()
	$MusicPlayer.set_section(section, intensity, $StructuralEngine.cycleCount)
	$ScoreNode2D.stage = $StructuralEngine.cycleCount
	var gameplayHandler = $OptionMenuNode2D/GameplayHandler
	gameplayHandler.bpmIncrease += 1
	gameplayHandler.bpm += 1
	$Conductor.bpm = gameplayHandler.bpm
	if section == 3:
		_show_options_menu()

func _on_conductor_subdivision(conductorPosition: Variant) -> void:
	$MusicPlayer.play_on_subdivision(conductorPosition, currentChord)

func _on_music_player_note_scheduled(_instrument: int, chord_idx: int, sound_id: int) -> void:
	spawnNote(chord_idx, sound_id)

func _sync_player_controlled_instruments() -> void:
	var musicPlayer = $MusicPlayer
	var gameplayHandler = $OptionMenuNode2D/GameplayHandler

	for instrument in musicPlayer.Instrument.values():
		musicPlayer.set_player_controlled(instrument, false)

	var ranked: Array = musicPlayer.GENRE_PLAYER_INSTRUMENTS[musicPlayer.currentGenre]
	var count: int = gameplayHandler.numberOfInstrumentsPlayed[musicPlayer.currentGenre]
	for i in min(count, ranked.size()):
		musicPlayer.set_player_controlled(ranked[i], true)

	musicPlayer.set_player_controlled(
		musicPlayer.Instrument.CHORD_STAB,
		musicPlayer.playerControlledInstruments.get(musicPlayer.Instrument.RHODES, false)
	)

	musicPlayer.densityMultiplier = gameplayHandler.globalDensityMultiplier
	musicPlayer.novelty = gameplayHandler.novelty

	_update_instrument_icons()

const HEART_CELL_SIZE: int = 44

const ICON_ACTIVE_ALPHA: float = 1.0
const ICON_INACTIVE_ALPHA: float = 0.25

func _update_instrument_icons() -> void:
	var controlled = $MusicPlayer.playerControlledInstruments
	var musicPlayer = $MusicPlayer
	$PianoIcon.modulate.a = ICON_ACTIVE_ALPHA if controlled.get(musicPlayer.Instrument.RHODES,       false) else ICON_INACTIVE_ALPHA
	$DrumIcon.modulate.a  = ICON_ACTIVE_ALPHA if controlled.get(musicPlayer.Instrument.KICK,         false) else ICON_INACTIVE_ALPHA
	$CongaIcon.modulate.a = ICON_ACTIVE_ALPHA if controlled.get(musicPlayer.Instrument.CONGA_SLAP,   false) else ICON_INACTIVE_ALPHA
	$ClapIcon.modulate.a  = ICON_ACTIVE_ALPHA if controlled.get(musicPlayer.Instrument.CLAP,         false) else ICON_INACTIVE_ALPHA

func _on_option_selected(option_index: int) -> void:
	var gameplayHandler = $OptionMenuNode2D/GameplayHandler
	options[option_index].action.call()
	$Conductor.bpm = gameplayHandler.bpm
	_apply_lanes_keys()
	_sync_player_controlled_instruments()
	_rebuild_hearts()
	_hide_options_menu()
	_set_paused(false)

func _on_option_1_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton && event.pressed:
		_on_option_selected(0)

func _on_option_2_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton && event.pressed:
		_on_option_selected(1)

func _on_option_3_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton && event.pressed:
		_on_option_selected(2)


func _on_music_player_genre_changed(newBpm: int) -> void:
	var gameplayHandler = $OptionMenuNode2D/GameplayHandler
	gameplayHandler.currentGenre = $MusicPlayer.currentGenre
	gameplayHandler.numberOfInstrumentsPlayed[$MusicPlayer.currentGenre] = 1
	gameplayHandler.bpm = newBpm + gameplayHandler.bpmIncrease
	$Conductor.bpm = gameplayHandler.bpm
	$ChordGenerator.set_genre($MusicPlayer.currentGenre)
	_sync_player_controlled_instruments()

func _on_ready() -> void:
	$Conductor.bpm = $OptionMenuNode2D/GameplayHandler.bpm
	$GameOver.visible = false
	_lowPassFilter = AudioEffectLowPassFilter.new()
	_lowPassFilter.cutoff_hz = LOWPASS_CUTOFF_NORMAL
	AudioServer.add_bus_effect(AudioServer.get_bus_index("Master"), _lowPassFilter)
	_sync_player_controlled_instruments()
	_rebuild_hearts.call_deferred()
	$MainMenu.started.connect(_hide_main_menu)
	_show_main_menu()
	get_viewport().physics_object_picking = true
