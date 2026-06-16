extends Node

var bpm: int = 100
var numberOfLives: int = 10
var comboMultiplier: int = 1
var scoreMultiplier: float = 1.0
var activeLanes: Array[bool] = [true, true, true, true]
var lanesKeys: Array[String] = ["", "", "", ""]

var spawnNoteOnRhodes: bool = true
var spawnNoteOnDrumKick: bool = true
var spawnNoteOnDrumHiHatOpen: bool = false
var spawnNoteOnDrumHiHatClose: bool = false
var spawnNoteOnDrumClap: bool = false

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
		"Score Multiplier x2, but BPM increased to 140!",
		func(): scoreMultiplier = 2.0; bpm = 140
	),
	Option.new(
		"Combo multiplier x2, but double notes probability +25%",
		func(): comboMultiplier = 2; spawnDoubleNotesProb += 0.25
	),
	Option.new(
		"Combo multiplier x3, but triple notes probability +25%",
		func(): comboMultiplier = 3; spawnTripleNotesProb += 0.25
	),
]

func getOptions() -> Array[Option]:
	return [options[0], options[1], options[2]]
