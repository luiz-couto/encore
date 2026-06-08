extends Node

enum Chord { C_MAJ, D_MIN, E_MIN, F_MAJ, G_MAJ, A_MIN, B_DIM };

const MAJOR_MATRIX = [
	[0.0,  0.0,  0.0,  0.44, 0.44, 0.0,  0.11], # C maj (I)
	[0.31, 0.0,  0.0,  0.31, 0.31, 0.0,  0.08], # D min (II)
	[0.31, 0.0,  0.0,  0.31, 0.31, 0.0,  0.08], # E min (III)
	[0.44, 0.0,  0.0,  0.0,  0.44, 0.0,  0.11], # F maj (IV)
	[0.8,  0.0,  0.0,  0.16, 0.0,  0.0,  0.04], # G maj (V)
	[0.31, 0.0,  0.0,  0.31, 0.31, 0.0,  0.08], # A min (VI)
	[0.71, 0.0,  0.0,  0.14, 0.14, 0.0,  0.0 ], # B dim (VII)
];

const MINOR_MATRIX = [
	[0.0, 0.31, 0.31, 0.0,  0.0,  0.31, 0.08], # C maj (III)
	[0.0, 0.0,  0.44, 0.0,  0.0,  0.44, 0.11], # D min (IV)
	[0.0, 0.16, 0.0,  0.0,  0.0,  0.8,  0.04], # E min (V)
	[0.0, 0.31, 0.31, 0.0,  0.0,  0.31, 0.08], # F maj (VI)
	[0.0, 0.31, 0.31, 0.0,  0.0,  0.31, 0.08], # G maj (VII)
	[0.0, 0.44, 0.44, 0.0,  0.0,  0.0,  0.11], # A min (I)
	[0.0, 0.14, 0.71, 0.0,  0.0,  0.14, 0.0 ], # B dim (II)
];

## 0.0 = fully C major, 1.0 = fully A minor
@export var mode: float = 0.5;

var current_chord: int = Chord.C_MAJ;

signal chord_changed(chord_idx: int);

func advance() -> int:
	var row = _blended_row(current_chord)
	current_chord = _weighted_sample(row)
	chord_changed.emit(current_chord)
	return current_chord

func _blended_row(idx: int) -> Array:
	var result = []
	for i in 7:
		var res = lerp(MAJOR_MATRIX[idx][i], MINOR_MATRIX[idx][i], mode);
		print("lerp res: ", res);
		result.append(res);
	return result

func _weighted_sample(weights: Array) -> int:
	var r = randf()
	var cumulative = 0.0
	for i in weights.size():
		cumulative += weights[i]
		if r <= cumulative:
			return i
	return weights.size() - 1
