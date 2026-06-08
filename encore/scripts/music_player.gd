extends Node

# Semitone offsets from C4 for each chord (root, third, fifth)
const CHORD_NOTES: Dictionary = {
	0: [0,  4,  7,  12], # C maj: C4, E4, G4, C5
	1: [2,  5,  9,  14], # D min: D4, F4, A4, D5
	2: [4,  7,  11, 16], # E min: E4, G4, B4, E5
	3: [5,  9,  12, 17], # F maj: F4, A4, C5, F5
	4: [7,  11, 14, 19], # G maj: G4, B4, D5, G5
	5: [9,  12, 16, 21], # A min: A4, C5, E5, A5
	6: [11, 14, 17, 23], # B dim: B4, D5, F5, B5
}

func play_chord(chord_idx: int) -> void:
	var notes = CHORD_NOTES[chord_idx];
	for i in 4:
		var player: AudioStreamPlayer2D = get_child(i);
		player.pitch_scale = pow(2.0, notes[i] / 12.0);
		player.play();

func play_note(chord_idx: int, lane: int) -> void:
	var semitones = CHORD_NOTES[chord_idx][lane];
	var player: AudioStreamPlayer2D = get_child(lane);
	player.pitch_scale = pow(2.0, semitones / 12.0);
	player.play();
