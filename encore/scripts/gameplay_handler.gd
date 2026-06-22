extends Node

var bpm: int = 135
var bpmIncrease: int = 0
var numberOfLives: int = 10
var comboMultiplier: int = 1
var scoreMultiplier: float = 1.0
var activeLanes: Array[bool] = [true, true, true, true]
var lanesKeys: Array[String] = ["", "", "", ""]

var spawnDoubleNotesProb: float = 0.0
var spawnTripleNotesProb: float = 0.0

var globalDensityMultiplier: float = 1.0
var novelty: float = 0.0
var livesLostPerMiss: int = 1
var currentGenre: int = 0

# Matches music_player.gd Genre enum: HOUSE=0, TECH_HOUSE=1, TECHNO=2, MELODIC_HOUSE=3, AFRO_HOUSE=4, AFRO_TECHNO=5
const GENRE_MAX_INSTRUMENTS: Dictionary = { 0: 2, 1: 2, 2: 1, 3: 2, 4: 2, 5: 2 }
var numberOfInstrumentsPlayed: Dictionary = { 0: 1, 1: 1, 2: 1, 3: 1, 4: 1, 5: 1 }

const MAX_LIVES: int = 25

class Option:
	var label: String
	var action: Callable
	var condition: Callable

	func _init(p_label: String, p_action: Callable, p_condition: Callable = func(): return true) -> void:
		label = p_label
		action = p_action
		condition = p_condition

var options: Array[Option] = [
	# -- Score / Multiplier --
	Option.new(
		"Score x2, BPM +3",
		func(): scoreMultiplier *= 2.0; bpmIncrease += 3; bpm += 3
	),
	Option.new(
		"Score x3, BPM +5",
		func(): scoreMultiplier *= 3.0; bpmIncrease += 5; bpm += 5,
		func(): return bpm < 155
	),
	Option.new(
		"Score x1.5, Combo +1, but BPM +3",
		func(): scoreMultiplier *= 1.5; comboMultiplier += 1; bpmIncrease += 3; bpm += 3
	),
	Option.new(
		"Combo +2, BPM +3",
		func(): comboMultiplier += 2; bpmIncrease += 3; bpm += 3
	),
	Option.new(
		"Score x3, Combo resets to 1",
		func(): scoreMultiplier *= 3.0; comboMultiplier = 1
	),
	Option.new(
		"Score x4, BPM +5, but triples more likely",
		func(): scoreMultiplier *= 4.0; bpmIncrease += 5; bpm += 5; spawnTripleNotesProb = min(spawnTripleNotesProb + 0.2, 1.0)
	),
	# -- BPM --
	Option.new(
		"BPM -3, Score x0.75",
		func(): bpmIncrease -= 3; bpm -= 3; scoreMultiplier *= 0.75,
		func(): return bpm > 110
	),
	Option.new(
		"BPM -5, Score x0.5",
		func(): bpmIncrease -= 5; bpm -= 5; scoreMultiplier *= 0.5,
		func(): return bpm > 115
	),
	Option.new(
		"BPM -3, but miss costs 2 lives",
		func(): bpmIncrease -= 3; bpm -= 3; livesLostPerMiss = 2,
		func(): return bpm > 110 and livesLostPerMiss == 1 and numberOfLives > 3
	),
	Option.new(
		"BPM -5, but notes more often in pairs",
		func(): bpmIncrease -= 5; bpm -= 5; spawnDoubleNotesProb = min(spawnDoubleNotesProb + 0.3, 1.0),
		func(): return bpm > 115
	),
	Option.new(
		"BPM -3, but Combo resets to 1",
		func(): bpmIncrease -= 3; bpm -= 3; comboMultiplier = 1,
		func(): return bpm > 110 and comboMultiplier >= 2
	),
	Option.new(
		"BPM -4, but triples more likely, Score x0.75",
		func(): bpmIncrease -= 4; bpm -= 4; spawnTripleNotesProb = min(spawnTripleNotesProb + 0.2, 1.0); scoreMultiplier *= 0.75,
		func(): return bpm > 112
	),
	# -- Lives --
	Option.new(
		"+3 lives, Score x0.5",
		func(): numberOfLives = min(numberOfLives + 3, MAX_LIVES); scoreMultiplier *= 0.5,
		func(): return numberOfLives < MAX_LIVES
	),
	Option.new(
		"+5 lives, BPM +5",
		func(): numberOfLives = min(numberOfLives + 5, MAX_LIVES); bpmIncrease += 5; bpm += 5,
		func(): return numberOfLives <= MAX_LIVES - 5
	),
	Option.new(
		"Miss costs 2 lives, Score x3",
		func(): livesLostPerMiss = 2; scoreMultiplier *= 3.0,
		func(): return livesLostPerMiss == 1 and numberOfLives > 5
	),
	Option.new(
		"Miss costs 3 lives, Score x5",
		func(): livesLostPerMiss = 3; scoreMultiplier *= 5.0,
		func(): return livesLostPerMiss <= 2 and numberOfLives > 10
	),
	# -- Music Density --
	Option.new(
		"Score x1.5, but more notes in patterns",
		func(): globalDensityMultiplier *= 1.5; scoreMultiplier *= 1.5,
		func(): return globalDensityMultiplier < 2.5
	),
	Option.new(
		"Score x2, but fewer notes in patterns",
		func(): globalDensityMultiplier *= 0.5; scoreMultiplier *= 2.0,
		func(): return globalDensityMultiplier > 0.3
	),
	Option.new(
		"Score x2, BPM +3, but twice as many notes",
		func(): globalDensityMultiplier *= 2.0; bpmIncrease += 3; bpm += 3; scoreMultiplier *= 2.0,
		func(): return globalDensityMultiplier < 1.5
	),
	# -- Novelty --
	Option.new(
		"Score x1.5, but patterns more unpredictable",
		func(): novelty = min(novelty + 0.3, 1.0); scoreMultiplier *= 1.5,
		func(): return novelty < 0.7
	),
	Option.new(
		"Score x2, BPM +3, but patterns much more unpredictable",
		func(): novelty = min(novelty + 0.5, 1.0); scoreMultiplier *= 2.0; bpmIncrease += 3; bpm += 3,
		func(): return novelty < 0.5
	),
	# -- Notes --
	Option.new(
		"Score x1.5, but notes more likely to come in pairs",
		func(): spawnDoubleNotesProb = min(spawnDoubleNotesProb + 0.25, 1.0); scoreMultiplier *= 1.5
	),
	Option.new(
		"Score x2, but triples more likely",
		func(): spawnTripleNotesProb = min(spawnTripleNotesProb + 0.2, 1.0); scoreMultiplier *= 2.0
	),
	Option.new(
		"Score x2, BPM +3, but more pairs and triples",
		func(): spawnDoubleNotesProb = min(spawnDoubleNotesProb + 0.2, 1.0); spawnTripleNotesProb = min(spawnTripleNotesProb + 0.15, 1.0); bpmIncrease += 3; bpm += 3; scoreMultiplier *= 2.0
	),
	Option.new(
		"Combo +1, but notes more often in pairs",
		func(): comboMultiplier += 1; spawnDoubleNotesProb = min(spawnDoubleNotesProb + 0.3, 1.0)
	),
	# -- Lanes --
	Option.new(
		"Lane 4 disabled, Score x2, but BPM +5",
		func(): activeLanes[3] = false; scoreMultiplier *= 2.0; bpmIncrease += 5; bpm += 5,
		func(): return activeLanes[3]
	),
	Option.new(
		"Lane 1 disabled, Combo +2, but BPM +5",
		func(): activeLanes[0] = false; comboMultiplier += 2; bpmIncrease += 5; bpm += 5,
		func(): return activeLanes[0]
	),
	Option.new(
		"Center lanes only, Score x3, but BPM +8",
		func(): activeLanes[0] = false; activeLanes[3] = false; scoreMultiplier *= 3.0; bpmIncrease += 8; bpm += 8,
		func(): return activeLanes[0] and activeLanes[3]
	),
	# -- Instruments --
	Option.new(
		"+1 instrument this genre, Combo +1, but BPM +3",
		func(): numberOfInstrumentsPlayed[currentGenre] += 1; comboMultiplier += 1; bpmIncrease += 3; bpm += 3,
		func(): return numberOfInstrumentsPlayed[currentGenre] < GENRE_MAX_INSTRUMENTS[currentGenre]
	),
	Option.new(
		"1 fewer instrument this genre, Score x2, but BPM +4",
		func(): numberOfInstrumentsPlayed[currentGenre] -= 1; scoreMultiplier *= 2.0; bpmIncrease += 4; bpm += 4,
		func(): return numberOfInstrumentsPlayed[currentGenre] > 1
	),
]

func getOptions() -> Array:
	var available: Array = []
	for opt in options:
		if opt.condition.call():
			available.append(opt)
	available.shuffle()
	if available.size() < 3:
		var fallback = options.duplicate()
		fallback.shuffle()
		for opt in fallback:
			if available.size() >= 3:
				break
			if opt not in available:
				available.append(opt)
	return [available[0], available[1], available[2]]
