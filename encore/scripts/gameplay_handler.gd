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
	# -- Score (no BPM changes) --
	Option.new(
		"Score x2, but notes more often in pairs",
		func(): scoreMultiplier *= 2.0; spawnDoubleNotesProb = min(spawnDoubleNotesProb + 0.1, 1.0)
	),
	Option.new(
		"Score x2, but notes more often in pairs",
		func(): scoreMultiplier *= 2.0; spawnDoubleNotesProb = min(spawnDoubleNotesProb + 0.1, 1.0)
	),
	Option.new(
		"Score x2, but triples more likely",
		func(): scoreMultiplier *= 2.0; spawnTripleNotesProb = min(spawnTripleNotesProb + 0.1, 1.0)
	),
	Option.new(
		"Score x3, but miss costs 2 lives",
		func(): scoreMultiplier *= 3.0; livesLostPerMiss = 2,
		func(): return livesLostPerMiss == 1 and numberOfLives > 5
	),
	Option.new(
		"Score x4, but miss costs 3 lives",
		func(): scoreMultiplier *= 4.0; livesLostPerMiss = 3,
		func(): return livesLostPerMiss <= 2 and numberOfLives > 10
	),
	Option.new(
		"Score x2, but more notes in patterns",
		func(): scoreMultiplier *= 2.0; globalDensityMultiplier *= 1.5,
		func(): return globalDensityMultiplier < 2.5
	),
	Option.new(
		"Score x1.5, but fewer notes in patterns",
		func(): scoreMultiplier *= 1.5; globalDensityMultiplier *= 0.6,
		func(): return globalDensityMultiplier > 0.3
	),
	Option.new(
		"Score x1.5, but patterns more unpredictable",
		func(): scoreMultiplier *= 1.5; novelty = min(novelty + 0.2, 1.0),
		func(): return novelty < 0.8
	),
	Option.new(
		"Score x2, but patterns very unpredictable",
		func(): scoreMultiplier *= 2.0; novelty = min(novelty + 0.35, 1.0),
		func(): return novelty < 0.65
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
	# -- BPM Down (no score changes) --
	Option.new(
		"BPM -3, but notes more often in pairs",
		func(): bpmIncrease -= 3; bpm -= 3; spawnDoubleNotesProb = min(spawnDoubleNotesProb + 0.1, 1.0),
		func(): return bpm > 110
	),
	Option.new(
		"BPM -3, but notes more often in pairs",
		func(): bpmIncrease -= 3; bpm -= 3; spawnDoubleNotesProb = min(spawnDoubleNotesProb + 0.1, 1.0),
		func(): return bpm > 110
	),
	Option.new(
		"BPM -5, but notes more often in pairs",
		func(): bpmIncrease -= 5; bpm -= 5; spawnDoubleNotesProb = min(spawnDoubleNotesProb + 0.15, 1.0),
		func(): return bpm > 115
	),
	Option.new(
		"BPM -3, but triples more likely",
		func(): bpmIncrease -= 3; bpm -= 3; spawnTripleNotesProb = min(spawnTripleNotesProb + 0.1, 1.0),
		func(): return bpm > 110
	),
	Option.new(
		"BPM -5, but triples more likely",
		func(): bpmIncrease -= 5; bpm -= 5; spawnTripleNotesProb = min(spawnTripleNotesProb + 0.15, 1.0),
		func(): return bpm > 115
	),
	Option.new(
		"BPM -3, but patterns more unpredictable",
		func(): bpmIncrease -= 3; bpm -= 3; novelty = min(novelty + 0.2, 1.0),
		func(): return bpm > 110 and novelty < 0.8
	),
	Option.new(
		"BPM -5, but patterns more unpredictable",
		func(): bpmIncrease -= 5; bpm -= 5; novelty = min(novelty + 0.25, 1.0),
		func(): return bpm > 115 and novelty < 0.75
	),
	Option.new(
		"BPM -4, but miss costs 2 lives",
		func(): bpmIncrease -= 4; bpm -= 4; livesLostPerMiss = 2,
		func(): return bpm > 112 and livesLostPerMiss == 1 and numberOfLives > 3
	),
	Option.new(
		"BPM -5, but more notes in patterns",
		func(): bpmIncrease -= 5; bpm -= 5; globalDensityMultiplier *= 1.5,
		func(): return bpm > 115 and globalDensityMultiplier < 2.5
	),
	# -- BPM Up (paired with something good) --
	Option.new(
		"BPM +3, but +4 lives",
		func(): bpmIncrease += 3; bpm += 3; numberOfLives = min(numberOfLives + 4, MAX_LIVES),
		func(): return numberOfLives <= MAX_LIVES - 4
	),
	Option.new(
		"BPM +5, but +6 lives",
		func(): bpmIncrease += 5; bpm += 5; numberOfLives = min(numberOfLives + 6, MAX_LIVES),
		func(): return numberOfLives <= MAX_LIVES - 6
	),
	Option.new(
		"BPM +3, but fewer notes in patterns",
		func(): bpmIncrease += 3; bpm += 3; globalDensityMultiplier *= 0.6,
		func(): return globalDensityMultiplier > 0.3
	),
	# -- Lives --
	Option.new(
		"+3 lives, but notes more often in pairs",
		func(): numberOfLives = min(numberOfLives + 3, MAX_LIVES); spawnDoubleNotesProb = min(spawnDoubleNotesProb + 0.1, 1.0),
		func(): return numberOfLives < MAX_LIVES
	),
	Option.new(
		"+3 lives, but notes more often in pairs",
		func(): numberOfLives = min(numberOfLives + 3, MAX_LIVES); spawnDoubleNotesProb = min(spawnDoubleNotesProb + 0.1, 1.0),
		func(): return numberOfLives < MAX_LIVES
	),
	Option.new(
		"+3 lives, but triples more likely",
		func(): numberOfLives = min(numberOfLives + 3, MAX_LIVES); spawnTripleNotesProb = min(spawnTripleNotesProb + 0.1, 1.0),
		func(): return numberOfLives < MAX_LIVES
	),
	Option.new(
		"+3 lives, but patterns more unpredictable",
		func(): numberOfLives = min(numberOfLives + 3, MAX_LIVES); novelty = min(novelty + 0.2, 1.0),
		func(): return numberOfLives < MAX_LIVES and novelty < 0.8
	),
	Option.new(
		"+5 lives, but more notes in patterns",
		func(): numberOfLives = min(numberOfLives + 5, MAX_LIVES); globalDensityMultiplier *= 1.5,
		func(): return numberOfLives <= MAX_LIVES - 5 and globalDensityMultiplier < 2.5
	),
	Option.new(
		"Miss costs 2 lives, but +6 lives",
		func(): livesLostPerMiss = 2; numberOfLives = min(numberOfLives + 6, MAX_LIVES),
		func(): return livesLostPerMiss == 1
	),
	# -- Novelty --
	Option.new(
		"Patterns more unpredictable, but BPM -3",
		func(): novelty = min(novelty + 0.2, 1.0); bpmIncrease -= 3; bpm -= 3,
		func(): return novelty < 0.8 and bpm > 110
	),
	Option.new(
		"Patterns more unpredictable, but Score x1.5",
		func(): novelty = min(novelty + 0.2, 1.0); scoreMultiplier *= 1.5,
		func(): return novelty < 0.8
	),
	Option.new(
		"Patterns more unpredictable, but fewer notes in patterns",
		func(): novelty = min(novelty + 0.2, 1.0); globalDensityMultiplier *= 0.6,
		func(): return novelty < 0.8 and globalDensityMultiplier > 0.3
	),
	Option.new(
		"Patterns very unpredictable, but +3 lives",
		func(): novelty = min(novelty + 0.4, 1.0); numberOfLives = min(numberOfLives + 3, MAX_LIVES),
		func(): return novelty < 0.6 and numberOfLives < MAX_LIVES
	),
	Option.new(
		"Patterns more unpredictable, but +4 lives",
		func(): novelty = min(novelty + 0.2, 1.0); numberOfLives = min(numberOfLives + 4, MAX_LIVES),
		func(): return novelty < 0.8 and numberOfLives < MAX_LIVES
	),
	# -- Notes --
	Option.new(
		"Notes more often in pairs, but BPM -3",
		func(): spawnDoubleNotesProb = min(spawnDoubleNotesProb + 0.1, 1.0); bpmIncrease -= 3; bpm -= 3,
		func(): return bpm > 110
	),
	Option.new(
		"Notes more often in pairs, but +3 lives",
		func(): spawnDoubleNotesProb = min(spawnDoubleNotesProb + 0.1, 1.0); numberOfLives = min(numberOfLives + 3, MAX_LIVES),
		func(): return numberOfLives < MAX_LIVES
	),
	Option.new(
		"Triples more likely, but BPM -4",
		func(): spawnTripleNotesProb = min(spawnTripleNotesProb + 0.1, 1.0); bpmIncrease -= 4; bpm -= 4,
		func(): return bpm > 112
	),
	Option.new(
		"Notes more often in pairs, but fewer notes in patterns",
		func(): spawnDoubleNotesProb = min(spawnDoubleNotesProb + 0.1, 1.0); globalDensityMultiplier *= 0.6,
		func(): return globalDensityMultiplier > 0.3
	),
	# -- Density (busier patterns = punishment, sparse = reward) --
	Option.new(
		"Busier patterns, but BPM -3",
		func(): globalDensityMultiplier *= 1.4; bpmIncrease -= 3; bpm -= 3,
		func(): return globalDensityMultiplier < 2.5 and bpm > 110
	),
	Option.new(
		"Busier patterns, but BPM -3",
		func(): globalDensityMultiplier *= 1.4; bpmIncrease -= 3; bpm -= 3,
		func(): return globalDensityMultiplier < 2.5 and bpm > 110
	),
	Option.new(
		"Busier patterns, but +3 lives",
		func(): globalDensityMultiplier *= 1.4; numberOfLives = min(numberOfLives + 3, MAX_LIVES),
		func(): return globalDensityMultiplier < 2.5 and numberOfLives < MAX_LIVES
	),
	Option.new(
		"Much busier patterns, but Score x2",
		func(): globalDensityMultiplier *= 2.0; scoreMultiplier *= 2.0,
		func(): return globalDensityMultiplier < 1.5
	),
	Option.new(
		"Busier patterns, but notes less often in pairs",
		func(): globalDensityMultiplier *= 1.4; spawnDoubleNotesProb = max(spawnDoubleNotesProb - 0.15, 0.0),
		func(): return globalDensityMultiplier < 2.5 and spawnDoubleNotesProb > 0.1
	),
	Option.new(
		"Fewer notes in patterns, but BPM +4",
		func(): globalDensityMultiplier *= 0.6; bpmIncrease += 4; bpm += 4,
		func(): return globalDensityMultiplier > 0.3
	),
	Option.new(
		"Fewer notes in patterns, but miss costs 2 lives",
		func(): globalDensityMultiplier *= 0.6; livesLostPerMiss = 2,
		func(): return globalDensityMultiplier > 0.3 and livesLostPerMiss == 1 and numberOfLives > 3
	),
	Option.new(
		"Fewer notes in patterns, but triples more likely",
		func(): globalDensityMultiplier *= 0.6; spawnTripleNotesProb = min(spawnTripleNotesProb + 0.15, 1.0),
		func(): return globalDensityMultiplier > 0.3
	),
	Option.new(
		"Fewer notes in patterns, but patterns more unpredictable",
		func(): globalDensityMultiplier *= 0.6; novelty = min(novelty + 0.25, 1.0),
		func(): return globalDensityMultiplier > 0.3 and novelty < 0.75
	),
	Option.new(
		"Fewer notes in patterns, but notes very often in pairs",
		func(): globalDensityMultiplier *= 0.6; spawnDoubleNotesProb = min(spawnDoubleNotesProb + 0.15, 1.0),
		func(): return globalDensityMultiplier > 0.3
	),
	# -- Lanes (lane disable = easier, so it's the reward — pair with a punishment) --
	Option.new(
		"Lane 4 disabled, but BPM +5",
		func(): activeLanes[3] = false; bpmIncrease += 5; bpm += 5,
		func(): return activeLanes[3]
	),
	Option.new(
		"Lane 1 disabled, but BPM +5",
		func(): activeLanes[0] = false; bpmIncrease += 5; bpm += 5,
		func(): return activeLanes[0]
	),
	Option.new(
		"Lane 4 disabled, but miss costs 2 lives",
		func(): activeLanes[3] = false; livesLostPerMiss = 2,
		func(): return activeLanes[3] and livesLostPerMiss == 1 and numberOfLives > 3
	),
	Option.new(
		"Lane 1 disabled, but miss costs 2 lives",
		func(): activeLanes[0] = false; livesLostPerMiss = 2,
		func(): return activeLanes[0] and livesLostPerMiss == 1 and numberOfLives > 3
	),
	Option.new(
		"Center lanes only, but triples much more likely",
		func(): activeLanes[0] = false; activeLanes[3] = false; spawnTripleNotesProb = min(spawnTripleNotesProb + 0.2, 1.0),
		func(): return activeLanes[0] and activeLanes[3]
	),
	Option.new(
		"Center lanes only, but miss costs 2 lives",
		func(): activeLanes[0] = false; activeLanes[3] = false; livesLostPerMiss = 2,
		func(): return activeLanes[0] and activeLanes[3] and livesLostPerMiss == 1 and numberOfLives > 3
	),
	Option.new(
		"Lane 4 disabled, but more notes in patterns",
		func(): activeLanes[3] = false; globalDensityMultiplier *= 1.5,
		func(): return activeLanes[3] and globalDensityMultiplier < 2.5
	),
	Option.new(
		"Lane 1 disabled, but more notes in patterns",
		func(): activeLanes[0] = false; globalDensityMultiplier *= 1.5,
		func(): return activeLanes[0] and globalDensityMultiplier < 2.5
	),
	Option.new(
		"Center lanes only, but patterns very unpredictable",
		func(): activeLanes[0] = false; activeLanes[3] = false; novelty = min(novelty + 0.35, 1.0),
		func(): return activeLanes[0] and activeLanes[3] and novelty < 0.65
	),
	Option.new(
		"Lane 4 disabled, but notes very often in pairs",
		func(): activeLanes[3] = false; spawnDoubleNotesProb = min(spawnDoubleNotesProb + 0.15, 1.0),
		func(): return activeLanes[3]
	),
	# -- Instruments (+1 = more notes = punishment, so pair with a reward) --
	Option.new(
		"+1 instrument this genre, but BPM -3",
		func(): numberOfInstrumentsPlayed[currentGenre] += 1; bpmIncrease -= 3; bpm -= 3,
		func(): return numberOfInstrumentsPlayed[currentGenre] < GENRE_MAX_INSTRUMENTS[currentGenre] and bpm > 110
	),
	Option.new(
		"+1 instrument this genre, but BPM -3",
		func(): numberOfInstrumentsPlayed[currentGenre] += 1; bpmIncrease -= 3; bpm -= 3,
		func(): return numberOfInstrumentsPlayed[currentGenre] < GENRE_MAX_INSTRUMENTS[currentGenre] and bpm > 110
	),
	Option.new(
		"+1 instrument this genre, but +3 lives",
		func(): numberOfInstrumentsPlayed[currentGenre] += 1; numberOfLives = min(numberOfLives + 3, MAX_LIVES),
		func(): return numberOfInstrumentsPlayed[currentGenre] < GENRE_MAX_INSTRUMENTS[currentGenre] and numberOfLives < MAX_LIVES
	),
	Option.new(
		"+1 instrument this genre, but +3 lives",
		func(): numberOfInstrumentsPlayed[currentGenre] += 1; numberOfLives = min(numberOfLives + 3, MAX_LIVES),
		func(): return numberOfInstrumentsPlayed[currentGenre] < GENRE_MAX_INSTRUMENTS[currentGenre] and numberOfLives < MAX_LIVES
	),
	Option.new(
		"+1 instrument this genre, but Score x1.5",
		func(): numberOfInstrumentsPlayed[currentGenre] += 1; scoreMultiplier *= 1.5,
		func(): return numberOfInstrumentsPlayed[currentGenre] < GENRE_MAX_INSTRUMENTS[currentGenre]
	),
	Option.new(
		"+1 instrument this genre, but fewer notes in patterns",
		func(): numberOfInstrumentsPlayed[currentGenre] += 1; globalDensityMultiplier *= 0.6,
		func(): return numberOfInstrumentsPlayed[currentGenre] < GENRE_MAX_INSTRUMENTS[currentGenre] and globalDensityMultiplier > 0.3
	),
	Option.new(
		"+1 instrument this genre, but BPM -4",
		func(): numberOfInstrumentsPlayed[currentGenre] += 1; bpmIncrease -= 4; bpm -= 4,
		func(): return numberOfInstrumentsPlayed[currentGenre] < GENRE_MAX_INSTRUMENTS[currentGenre] and bpm > 112
	),
	# -- (1 fewer = easier, so pair with a punishment) --
	Option.new(
		"1 fewer instrument this genre, but BPM +5",
		func(): numberOfInstrumentsPlayed[currentGenre] -= 1; bpmIncrease += 5; bpm += 5,
		func(): return numberOfInstrumentsPlayed[currentGenre] > 1
	),
	Option.new(
		"1 fewer instrument this genre, but miss costs 2 lives",
		func(): numberOfInstrumentsPlayed[currentGenre] -= 1; livesLostPerMiss = 2,
		func(): return numberOfInstrumentsPlayed[currentGenre] > 1 and livesLostPerMiss == 1 and numberOfLives > 3
	),
	Option.new(
		"1 fewer instrument this genre, but triples more likely",
		func(): numberOfInstrumentsPlayed[currentGenre] -= 1; spawnTripleNotesProb = min(spawnTripleNotesProb + 0.15, 1.0),
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
