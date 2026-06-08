extends Node

@export var bpm: float = 55:
	set(value):
		bpm = value
		secondsPerBeat = 60.0 / bpm

@export var measures: float = 4;

var secondsPerBeat: float = 60 / bpm;
var lastReportedBeat: float = 0;
var currMeasure: float = 1;
var startTime: float = 0.0;

signal beat(position);
signal measure(position);

func _physics_process(delta: float) -> void:
	var elapsed = (Time.get_ticks_msec() / 1000.0) - startTime;
	var currBeat = int(floor(elapsed / secondsPerBeat));
	if (lastReportedBeat < currBeat):
		if (currMeasure > measures):
			currMeasure = 1;
		beat.emit(currBeat);
		measure.emit(currMeasure);
		lastReportedBeat = currBeat;
		currMeasure += 1;

#func reportBeat() -> void:
	## This conditional guarantees that a new note is generated only in beats, not every frame
	#if (lastReportedBeat < currSongPositionInBeats):
		#if (currMeasure > measures):
			#currMeasure = 1;
		#beat.emit(currSongPositionInBeats);
		#measure.emit(currMeasure);
		#lastReportedBeat = currSongPositionInBeats;
		#currMeasure += 1;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	startTime = Time.get_ticks_msec() / 1000.0;

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
