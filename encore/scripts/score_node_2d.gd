extends Node2D

@export var score: int = 0;
@export var stage: int = 0;
@export var topStreak: int = 0;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	$ScoreLabelNum.text = var_to_str(score)
	$StageLabelNum.text = "STAGE: " + var_to_str(stage)
	$BestStreakLabelNum.text = "TOP STREAK: " + var_to_str(topStreak)
	pass
