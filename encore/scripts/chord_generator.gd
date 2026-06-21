extends Node

enum Chord { C_MAJ, D_MIN, E_MIN, F_MAJ, G_MAJ, A_MIN, B_DIM };
enum Genre { HOUSE = 0, TECH_HOUSE = 1, TECHNO = 2, MELODIC_HOUSE = 3, AFRO_HOUSE = 4, AFRO_TECHNO = 5 }

const PROGRESSIONS_BY_GENRE: Dictionary = {
	Genre.HOUSE: [  # Am-heavy classics
		[5, 4, 3, 4], # Am → G → F → G
		[5, 3, 0, 4], # Am → F → C → G
		[5, 1, 4, 0], # Am → Dm → G → C
		[5, 2, 3, 4], # Am → Em → F → G
		[1, 5, 3, 4], # Dm → Am → F → G
		[5, 3, 4, 3], # Am → F → G → F
	],
	Genre.TECH_HOUSE: [  # Dark/Modal
		[5, 2, 4, 3], # Am → Em → G → F
		[5, 6, 0, 4], # Am → Bdim → C → G
		[2, 1, 4, 5], # Em → Dm → G → Am
		[1, 2, 5, 4], # Dm → Em → Am → G
		[5, 2, 1, 4], # Am → Em → Dm → G
		[2, 5, 1, 4], # Em → Am → Dm → G
	],
	Genre.TECHNO: [  # Dark/Modal
		[5, 2, 4, 3],
		[5, 6, 0, 4],
		[2, 1, 4, 5],
		[1, 2, 5, 4],
		[5, 2, 1, 4],
		[2, 5, 1, 4],
	],
	Genre.MELODIC_HOUSE: [  # Bright/Major
		[0, 4, 5, 3], # C → G → Am → F
		[0, 5, 3, 4], # C → Am → F → G
		[0, 3, 4, 5], # C → F → G → Am
		[0, 1, 3, 4], # C → Dm → F → G
		[0, 2, 3, 4], # C → Em → F → G
		[0, 5, 1, 4], # C → Am → Dm → G
	],
	Genre.AFRO_HOUSE: [  # Am-heavy, warm groove
		[5, 4, 3, 4],
		[5, 3, 0, 4],
		[5, 1, 4, 0],
		[5, 2, 3, 4],
		[1, 5, 3, 4],
		[5, 3, 4, 3],
	],
	Genre.AFRO_TECHNO: [  # Dark/Modal
		[5, 2, 4, 3],
		[5, 6, 0, 4],
		[2, 1, 4, 5],
		[1, 2, 5, 4],
		[5, 2, 1, 4],
		[2, 5, 1, 4],
	],
}

const LOOPS_BEFORE_REFRESH = 4;

var activeProgressions: Array = PROGRESSIONS_BY_GENRE[Genre.TECHNO];
var currentProgression: Array = [];
var position: int = 0;
var loopCount: int = 0;

signal chordChanged(chordIdx);

func _ready() -> void:
	pick_progression();

func set_genre(genre: int) -> void:
	activeProgressions = PROGRESSIONS_BY_GENRE[genre];
	pick_progression();

func pick_progression():
	var randomIdx = randi_range(0, activeProgressions.size() - 1);
	position = 0;
	currentProgression = activeProgressions[randomIdx];

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
