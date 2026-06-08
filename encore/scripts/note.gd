extends Area2D

const SPAWN_Y: float = -16;
const TARGET_Y: float = 1200;
const DIST_TO_TARGET: float = TARGET_Y - SPAWN_Y;

const LANE_0_X = 680;
const LANE_0_SPAWN = Vector2(LANE_0_X, SPAWN_Y);

const LANE_1_X = 862;
const LANE_1_SPAWN = Vector2(LANE_1_X, SPAWN_Y);

const LANE_2_X = 1040;
const LANE_2_SPAWN = Vector2(LANE_2_X, SPAWN_Y);

const LANE_3_X = 1217;
const LANE_3_SPAWN = Vector2(LANE_3_X, SPAWN_Y);
 
const positionSelector: Dictionary[int, Vector2] = {
	0: LANE_0_SPAWN,
	1: LANE_1_SPAWN,
	2: LANE_2_SPAWN,
	3: LANE_3_SPAWN
};

var speed: float = 0;
var hit: bool = false;

var chord: int = 0

func initialize(lane: int, chord_idx: int):
	position = positionSelector[lane];
	$AnimatedSprite2D.frame = lane;
	speed = DIST_TO_TARGET / 2.0;
	chord = chord_idx;
	
func _physics_process(delta: float) -> void:
	if (!hit):
		position.y += speed * delta;
		if position.y > TARGET_Y + 20:
			queue_free();

func destroy(score: int) -> void:
	get_tree().get_root().get_node("Game/MusicPlayer").play_note(chord, $AnimatedSprite2D.frame);
	$Timer.start();
	hit = true;

func _on_timer_timeout() -> void:
	queue_free();

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
