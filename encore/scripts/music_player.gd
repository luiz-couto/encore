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

@export var piano_sample: AudioStream;
var playback: AudioStreamPlaybackPolyphonic

func _ready() -> void:
	$Player.stream = AudioStreamPolyphonic.new()
	$Player.play()
	playback = $Player.get_stream_playback()

func play_chord(chord_idx: int) -> void:
	for i in 4:
		var pitch = pow(2.0, CHORD_NOTES[chord_idx][i] / 12.0)
		playback.play_stream(piano_sample, 0, 0, pitch)


func play_note(chord_idx: int, lane: int) -> void:
	var pitch = pow(2.0, CHORD_NOTES[chord_idx][lane] / 12.0)
	playback.play_stream(piano_sample, 0, 0, pitch)
