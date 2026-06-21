extends Node

var bpm: int = 135
var numberOfLives: int = 1
var comboMultiplier: int = 1
var scoreMultiplier: float = 1.0
var activeLanes: Array[bool] = [true, true, true, true]
var lanesKeys: Array[String] = ["", "", "", ""]

var spawnNoteOnRhodes: bool = false
var spawnNoteOnDrumKick: bool = true
var spawnNoteOnDrumHiHatOpen: bool = false
var spawnNoteOnDrumHiHatClose: bool = false
var spawnNoteOnDrumClap: bool = false
var spawnNoteOnCongaOpen: bool = false
var spawnNoteOnCongaSlap: bool = false

var spawnDoubleNotesProb: float = 0.0
var spawnTripleNotesProb: float = 0.0

class Option:
	var label: String
	var action: Callable
	
	func _init(p_label: String, p_action	: Callable) -> void:
		label = p_label
		action = p_action

var options: Array[Option] = [
	Option.new(
		"Score x2, but BPM +20%",
		func(): scoreMultiplier *= 2.0; bpm = int(bpm * 1.2)
	),
	Option.new(
		"Combo +1, but double notes +25%",
		func(): comboMultiplier += 1; spawnDoubleNotesProb = min(spawnDoubleNotesProb + 0.25, 1.0)
	),
	Option.new(
		"Combo +2, but triple notes +25%",
		func(): comboMultiplier += 2; spawnTripleNotesProb = min(spawnTripleNotesProb + 0.25, 1.0)
	),
	Option.new(
		"Score x1.5, but BPM +15%",
		func(): scoreMultiplier *= 1.5; bpm = int(bpm * 1.15)
	),
	Option.new(
		"Score x3, but BPM +30% and double notes +15%",
		func(): scoreMultiplier *= 3.0; bpm = int(bpm * 1.3); spawnDoubleNotesProb = min(spawnDoubleNotesProb + 0.15, 1.0)
	),
	Option.new(
		"BPM -10%, but Score x0.75",
		func(): bpm = int(bpm * 0.9); scoreMultiplier *= 0.75
	),
	Option.new(
		"Kick notes enabled, Combo +1",
		func(): spawnNoteOnDrumKick = true; comboMultiplier += 1
	),
	Option.new(
		"Clap notes enabled, Score x1.3",
		func(): spawnNoteOnDrumClap = true; scoreMultiplier *= 1.3
	),
	Option.new(
		"Open hi-hat notes enabled, Combo +1",
		func(): spawnNoteOnDrumHiHatOpen = true; comboMultiplier += 1
	),
	Option.new(
		"Closed hi-hat notes enabled, BPM +10%",
		func(): spawnNoteOnDrumHiHatClose = true; bpm = int(bpm * 1.1)
	),
	Option.new(
		"All instrument notes enabled, Score x2 but BPM +20%",
		func(): spawnNoteOnRhodes = true; spawnNoteOnDrumKick = true; spawnNoteOnDrumClap = true; spawnNoteOnDrumHiHatOpen = true; spawnNoteOnDrumHiHatClose = true; scoreMultiplier *= 2.0; bpm = int(bpm * 1.2)
	),
	Option.new(
		"Lane 4 disabled, Score x2",
		func(): activeLanes[3] = false; scoreMultiplier *= 2.0
	),
	Option.new(
		"Lane 1 disabled, Combo +2",
		func(): activeLanes[0] = false; comboMultiplier += 2
	),
	Option.new(
		"Only center lanes active, Score x3",
		func(): activeLanes[0] = false; activeLanes[3] = false; scoreMultiplier *= 3.0
	),
	Option.new(
		"Double notes +20%, Score x1.5",
		func(): spawnDoubleNotesProb = min(spawnDoubleNotesProb + 0.2, 1.0); scoreMultiplier *= 1.5
	),
	Option.new(
		"Double notes +40%, Score x2 and Combo +1",
		func(): spawnDoubleNotesProb = min(spawnDoubleNotesProb + 0.4, 1.0); scoreMultiplier *= 2.0; comboMultiplier += 1
	),
	Option.new(
		"Triple notes +15%, Score x2",
		func(): spawnTripleNotesProb = min(spawnTripleNotesProb + 0.15, 1.0); scoreMultiplier *= 2.0
	),
	Option.new(
		"Chaos: double +20%, triple +10%, BPM +10%, Score x2",
		func(): spawnDoubleNotesProb = min(spawnDoubleNotesProb + 0.2, 1.0); spawnTripleNotesProb = min(spawnTripleNotesProb + 0.1, 1.0); bpm = int(bpm * 1.1); scoreMultiplier *= 2.0
	),
	Option.new(
		"Combo +2, but BPM +10%",
		func(): comboMultiplier += 2; bpm = int(bpm * 1.1)
	),
	Option.new(
		"Score x3, but Combo resets to 1",
		func(): scoreMultiplier *= 3.0; comboMultiplier = 1
	),
	Option.new(
		"Glass Cannon: Score x4, BPM +25%, triple notes +25%",
		func(): scoreMultiplier *= 4.0; bpm = int(bpm * 1.25); spawnTripleNotesProb = min(spawnTripleNotesProb + 0.25, 1.0)
	),
	Option.new(
		"Rhodes only: Combo +3, but Score x0.5 and all drum notes off",
		func(): spawnNoteOnDrumKick = false; spawnNoteOnDrumClap = false; spawnNoteOnDrumHiHatOpen = false; spawnNoteOnDrumHiHatClose = false; comboMultiplier += 3; scoreMultiplier *= 0.5
	),
	Option.new(
		"All notes + double +30%, Score x2.5, BPM +15%",
		func(): spawnNoteOnRhodes = true; spawnNoteOnDrumKick = true; spawnNoteOnDrumClap = true; spawnNoteOnDrumHiHatOpen = true; spawnNoteOnDrumHiHatClose = true; spawnDoubleNotesProb = min(spawnDoubleNotesProb + 0.3, 1.0); scoreMultiplier *= 2.5; bpm = int(bpm * 1.15)
	),
]

func getOptions() -> Array[Option]:
	var shuffled = options.duplicate()
	shuffled.shuffle()
	return [shuffled[0], shuffled[1], shuffled[2]]
