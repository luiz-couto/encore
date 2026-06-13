extends Node

enum Chord { C_MAJ, D_MIN, E_MIN, F_MAJ, G_MAJ, A_MIN, B_DIM };

const PROGRESSIONS = [
	[5, 4, 3, 4], # Am → G → F → G Dorian feel, most classic house
	[5, 3, 0, 4], # Am → F → C → G Natural minor loop
	[5, 1, 4, 0], # Am → Dm → G → C Classic four-chord
	[5, 2, 3, 4], # Am → Em → F → G Emotional/melodic house
	[1, 5, 3, 4], # Dm → Am → F → G Starts on iv, darker
	[5, 3, 4, 3], # Am → F  → G → F Minimal, three effective chords
]

const LOOPS_BEFORE_REFRESH = 4;

var currentProgression: Array = [];
var position: int = 0;
var loopCount: int = 0;

signal chordChanged(chordIdx);

func _ready() -> void:
	pick_progression();
	
func pick_progression():
	var randomIdx = randi_range(0, 5);
	position = 0;
	currentProgression = PROGRESSIONS[randomIdx];
	
func advance() -> int:
	var currChord = currentProgression[position];
	position = (position + 1) % currentProgression.size();
	if position == 0:
		loopCount += 1;
	chordChanged.emit(currChord);
	return currChord;
	
func maybeRefresh() -> void:
	if loopCount >= LOOPS_BEFORE_REFRESH:
		loopCount = 0;
		pick_progression();
