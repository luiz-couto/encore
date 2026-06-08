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

func play_chord(chord_idx: int) -> void:
	var notes = CHORD_NOTES[chord_idx];
	for i in 4:
		var player: AudioStreamPlayer2D = get_child(i);
		var newScale = pow(2.0, notes[i] / 12.0);
		if not player.playing or player.pitch_scale != newScale:
			player.pitch_scale = newScale;
			player.volume_db = -20.0
			player.play();
			var tween = create_tween();
			tween.tween_property(player, "volume_db", 0.0, 0.4)


func play_note(chord_idx: int, lane: int) -> void:
	var semitones = CHORD_NOTES[chord_idx][lane];
	var player: AudioStreamPlayer2D = get_child(lane);
	player.pitch_scale = pow(2.0, semitones / 12.0);
	player.play();
