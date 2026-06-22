extends Node

const SUBDIVISIONS_PER_MEASURE: int = 8

@export var bpm: float = 95:
	set(value):
		bpm = value
		secondsPerBeat = 60.0 / bpm
		secondsPerSubdiv = secondsPerBeat / 2
		if startTime > 0:
			startTime = Time.get_ticks_msec() / 1000.0 - lastReportedBeat * secondsPerBeat
			lastReportedSubdiv = int(lastReportedBeat) * 2

@export var measures: float = 4;

var secondsPerBeat: float = 60 / bpm;
var secondsPerSubdiv: float = secondsPerBeat / 2;
var lastReportedSubdiv: int = 1;
var currSubdiv: int = 1;

var lastReportedBeat: float = 0;
var currMeasure: float = 1;
var startTime: float = 0.0;

signal beat(position);
signal measure(position);
signal subdivision(position);

func _physics_process(_delta: float) -> void:
	var elapsed = (Time.get_ticks_msec() / 1000.0) - startTime;
	
	var currBeat = int(floor(elapsed / secondsPerBeat));
	if (lastReportedBeat < currBeat):
		if (currMeasure > measures):
			currMeasure = 1;
		beat.emit(currBeat);
		measure.emit(currMeasure);
		lastReportedBeat = currBeat;
		currMeasure += 1;
		
	var currSubdivBeat = int(floor(elapsed / secondsPerSubdiv))
	if lastReportedSubdiv < currSubdivBeat:
		if currSubdiv > measures * 2:  # 8 subdivisions per measure
			currSubdiv = 1
		subdivision.emit(currSubdiv)
		lastReportedSubdiv = currSubdivBeat
		currSubdiv += 1

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
func _process(_delta: float) -> void:
	pass
