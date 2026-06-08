extends Node

# Semitone offsets from C4 for each chord (root, third, fifth)
const CHORD_NOTES: Dictionary = {
	0: [0,   4,   7,  12], # C maj: C4, E4, G4, C5
	1: [-10, -7,  -3,  2], # D min: D3, F3, A3, D4
	2: [-8,  -5,  -1,  4], # E min: E3, G3, B3, E4
	3: [-7,  -3,   0,  5], # F maj: F3, A3, C4, F4
	4: [-5,  -1,   2,  7], # G maj: G3, B3, D4, G4
	5: [-3,   0,   4,  9], # A min: A3, C4, E4, A4
	6: [-1,   2,   5, 11], # B dim: B3, D4, F4, B4
}

@export var piano_c3: AudioStream
@export var piano_c4: AudioStream
@export var piano_c5: AudioStream

var playback: AudioStreamPlaybackPolyphonic

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
	for i in 4:
		var s = _get_stream(CHORD_NOTES[chord_idx][i])
		var pitch = pow(2.0, float(s[1]) / 12.0)
		playback.play_stream(s[0], 0, -4.0, pitch)

func play_note(chord_idx: int, lane: int) -> void:
	var s = _get_stream(CHORD_NOTES[chord_idx][lane])
	var pitch = pow(2.0, float(s[1]) / 12.0)
	playback.play_stream(s[0], 0, -4.0, pitch)
