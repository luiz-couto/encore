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

var playback: AudioStreamPlaybackPolyphonic

var active_chord_streams: Array = []

func _get_chord_stream(semitones: int) -> Array:
	if semitones < -9:  
		return [piano_c3, semitones + 12];
	else: 
		return [rhodes_c4, semitones];


func _ready() -> void:
	$Player.stream = AudioStreamPolyphonic.new()
	$Player.play()
	playback = $Player.get_stream_playback()

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
