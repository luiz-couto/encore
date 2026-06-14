extends Node

# Semitone offsets from C4 for each chord (root, third, fifth, seventh)
const CHORD_NOTES: Dictionary = {
	0: [0,  4,  7, 11],
	1: [-10, -7, -3,  0],
	2: [-8, -5, -1,  2],
	3: [-7, -3,  0,  4],
	4: [-5, -1,  2,  5],
	5: [-3,  0,  4,  7],
	6: [-1,  2,  5,  8],
}

@export var piano_c3: AudioStream
@export var piano_c4: AudioStream
@export var piano_c5: AudioStream

@export var rhodes_c4: AudioStream

@export var kick: AudioStream
@export var hihat_closed: AudioStream
@export var hihat_open: AudioStream
@export var clap: AudioStream

var playback: AudioStreamPlaybackPolyphonic
var drumPlayback: AudioStreamPlaybackPolyphonic

var active_chord_streams: Array = []
var currentSection: int = 0
var currentIntensity: float = 0.2

const KICK_BEATS: Dictionary = {
	0: [1],           # INTRO
	1: [1, 2, 3, 4],  # BUILD
	2: [1, 2, 3, 4],  # DROP
	3: [1, 3],        # BREAK
}

const CLAP_BEATS: Dictionary = {
	0: [],            # INTRO
	1: [4],           # BUILD
	2: [2, 4],        # DROP
	3: [],            # BREAK
}

const HIHAT_OPEN_SUBDIVS: Dictionary = {
	0: [],            # INTRO
	1: [4, 8],        # BUILD
	2: [8],           # DROP
	3: [],            # BREAK
}

const HIHAT_CLOSED_SUBDIVS: Dictionary = {
	0: [1, 3, 5, 7],           # INTRO — beats only
	1: [1, 2, 3, 5, 6, 7],     # BUILD — all except open positions
	2: [1, 2, 3, 4, 5, 6, 7],  # DROP — all except open position
	3: [1, 3, 5, 7],           # BREAK — beats only
}

const CHORD_STAB_SUBDIVS: Dictionary = {
	0: [1],           # INTRO — on beat 1
	1: [4, 8],        # BUILD — and-of-2, and-of-4
	2: [2, 4, 6, 8],  # DROP — every off-beat
	3: [4],           # BREAK — and-of-2 only
}

func set_section(section: int, intensity: float):
	currentSection = section
	currentIntensity = intensity
	
func _play_drum(stream: AudioStream, volume: float) -> void:
	drumPlayback.play_stream(stream, 0, volume, 1.0)
	
func play_on_beat(chord_idx: int, beat_pos: int) -> void:
	if beat_pos in KICK_BEATS[currentSection]:
		_play_drum(kick, -3.0)
	if beat_pos in CLAP_BEATS[currentSection]:
		_play_drum(clap, -5.0)

func play_on_subdivision(subdiv_pos: int, chord_idx: int) -> void:
	if subdiv_pos in HIHAT_OPEN_SUBDIVS[currentSection]:
		_play_drum(hihat_open, -8.0)
	elif subdiv_pos in HIHAT_CLOSED_SUBDIVS[currentSection]:
		_play_drum(hihat_closed, -10.0)
	if subdiv_pos in CHORD_STAB_SUBDIVS[currentSection]:
		play_chord(chord_idx)


func _get_chord_stream(semitones: int) -> Array:
	if semitones < -9:  
		return [piano_c3, semitones + 12];
	else: 
		return [rhodes_c4, semitones];

func _ready() -> void:
	$Player.stream = AudioStreamPolyphonic.new()
	$Player.play()
	playback = $Player.get_stream_playback()
	
	$DrumPlayer.stream = AudioStreamPolyphonic.new()
	$DrumPlayer.play()
	drumPlayback = $DrumPlayer.get_stream_playback()

func _get_stream(semitones: int) -> Array:
	if semitones < -6:
		return [piano_c3, semitones + 12]
	elif semitones > 6:
		return [piano_c5, semitones - 12]
	else:
		return [piano_c4, semitones]

func play_chord(chord_idx: int) -> void:
	for id in active_chord_streams:
		if playback.is_stream_playing(id):
			playback.stop_stream(id);
	
	active_chord_streams.clear()
	
	for i in 4:
		var selectedStream = _get_chord_stream(CHORD_NOTES[chord_idx][i])
		var pitch = pow(2.0, float(selectedStream[1]) / 12.0)
		var id = playback.play_stream(selectedStream[0], 0, -6.0, pitch)
		active_chord_streams.append(id)

func play_note(chord_idx: int, lane: int) -> void:
	var selectedStream = _get_stream(CHORD_NOTES[chord_idx][lane])
	var pitch = pow(2.0, float(selectedStream[1]) / 12.0)
	playback.play_stream(selectedStream[0], 0, -4.0, pitch)
