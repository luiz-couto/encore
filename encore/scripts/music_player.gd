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
@export var bass: AudioStream

var playback: AudioStreamPlaybackPolyphonic
var drumPlayback: AudioStreamPlaybackPolyphonic
var bass_playback: AudioStreamPlaybackPolyphonic

var active_chord_streams: Array = []
var currentSection: int = 0
var currentIntensity: float = 0.2
var currentCycle: int = 0
var active_bass_id: int = 0

var currentBar: int = 0
var isFill: bool = false
func set_bar(bar: int, fill: bool) -> void:
	currentBar = bar
	isFill = fill


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

# const HIHAT_OPEN_SUBDIVS: Dictionary = {
# 	0: [],            # INTRO
# 	1: [4, 8],        # BUILD
# 	2: [],           # DROP
# 	3: [],            # BREAK
# }

const HIHAT_CLOSED_SUBDIVS: Dictionary = {
	0: [1, 3, 5, 7],           # INTRO — beats only
	1: [1, 2, 3, 5, 6, 7],     # BUILD — all except open positions
	2: [1, 2, 3, 4, 5, 6, 7, 8],  # DROP — all except open position
	3: [1, 3, 5, 7],           # BREAK — beats only
}

const CHORD_STAB_SUBDIVS: Dictionary = {
	0: [1],           # INTRO — on beat 1
	1: [4, 8],        # BUILD — and-of-2, and-of-4
	2: [2, 4, 6, 8],  # DROP — every off-beat
	3: [4],           # BREAK — and-of-2 only
}

const BUILD_RAMP_STABS: Array = [
	[8],           # bars 0-1
	[4, 8],        # bars 2-3
	[4, 6, 8],     # bars 4-5
	[2, 4, 6, 8],  # bars 6-7
]

const BASS_BEATS: Dictionary = {
	0: [1],           # INTRO — root on beat 1 only
	1: [1, 3],        # BUILD — beats 1 and 3
	2: [1, 2, 3, 4],  # DROP — every beat
	3: [1],           # BREAK — beat 1 only
}

func _play_bass(chord_idx: int) -> void:
	if bass_playback.is_stream_playing(active_bass_id):
		bass_playback.stop_stream(active_bass_id)
	var semitones = CHORD_NOTES[chord_idx][0]  # root note of chord
	var pitch = pow(2.0, float(semitones) / 12.0)
	active_bass_id = bass_playback.play_stream(bass, 0, -4.0, pitch)


func set_section(section: int, intensity: float, cycle: int):
	currentSection = section
	currentIntensity = intensity
	currentCycle = cycle

func _play_drum(stream: AudioStream, volume: float) -> void:
	var volumeRnd = volume + randf_range(-1.5, 1.5)
	drumPlayback.play_stream(stream, 0, volumeRnd, 1.0)
	
func play_on_beat(chord_idx: int, beat_pos: int) -> void:
	if beat_pos in KICK_BEATS[currentSection]:
		_play_drum(kick, -3.0)
	if beat_pos in CLAP_BEATS[currentSection]:
		_play_drum(clap, -5.0)
	if beat_pos in BASS_BEATS[currentSection]:
		_play_bass(chord_idx)

func play_on_subdivision(subdiv_pos: int, chord_idx: int) -> void:
	if isFill:
		_play_drum(hihat_closed, -8.0)  # roll on every 8th note
		if subdiv_pos == 8 || subdiv_pos == 7:
			_play_drum(kick, -5.0) # extra kick on and-of-
	else:
		if subdiv_pos in HIHAT_OPEN_SUBDIVS[currentSection]:
			_play_drum(hihat_open, -8.0)
		elif subdiv_pos in HIHAT_CLOSED_SUBDIVS[currentSection]:
			_play_drum(hihat_closed, -10.0)

	# if currentSection == 1: # BUILD - use ramp
	# 	var rampIdx = min(currentBar / 4, BUILD_RAMP_STABS.size() - 1)
	# 	if subdiv_pos in BUILD_RAMP_STABS[rampIdx]:
	# 		play_chord(chord_idx)
	# else:
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

	$BassPlayer.stream = AudioStreamPolyphonic.new()
	$BassPlayer.play()
	bass_playback = $BassPlayer.get_stream_playback()


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
		var id = playback.play_stream(selectedStream[0], 0, -2.0, pitch)
		active_chord_streams.append(id)

func play_note(chord_idx: int, lane: int) -> void:
	var selectedStream = _get_stream(CHORD_NOTES[chord_idx][lane])
	var pitch = pow(2.0, float(selectedStream[1]) / 12.0)
	playback.play_stream(selectedStream[0], 0, -4.0, pitch)
