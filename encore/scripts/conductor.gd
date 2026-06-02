extends AudioStreamPlayer2D

@export var bpm: float = 115;
@export var measures: float = 4;
var secondsPerBeat: float = 60 / bpm;

var currSongPosition: float = 0.0;
var currSongPositionInBeats: float = 1;
var lastReportedBeat: float = 0;
var currMeasure: float = 1;

signal beat(position);
signal measure(position);

func _physics_process(delta: float) -> void:
	if (playing):
		currSongPosition = get_playback_position() + AudioServer.get_time_since_last_mix();
		currSongPosition = currSongPosition - AudioServer.get_output_latency();
		currSongPositionInBeats = int(floor(currSongPosition / secondsPerBeat));
		reportBeat();

func reportBeat() -> void:
	# This conditional guarantees that a new note is generated only in beats, not every frame
	if (lastReportedBeat < currSongPositionInBeats):
		if (currMeasure > measures):
			currMeasure = 1;
		beat.emit(currSongPositionInBeats);
		measure.emit(currMeasure);
		lastReportedBeat = currSongPositionInBeats;
		currMeasure += 1;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
