extends Area2D

const SPAWN_Y: float = -16;
const TARGET_Y: float = 1000;
const DIST_TO_TARGET: float = TARGET_Y - SPAWN_Y;

const LANE_0_X = 600;
const LANE_0_SPAWN = Vector2(LANE_0_X, SPAWN_Y);

const LANE_1_X = 700;
const LANE_1_SPAWN = Vector2(LANE_1_X, SPAWN_Y);

const LANE_2_X = 800;
const LANE_2_SPAWN = Vector2(LANE_2_X, SPAWN_Y);

const LANE_3_X = 900;
const LANE_3_SPAWN = Vector2(LANE_3_X, SPAWN_Y);
 
const positionSelector: Dictionary[int, Vector2] = {
	0: LANE_0_SPAWN,
	1: LANE_1_SPAWN,
	2: LANE_2_SPAWN,
	3: LANE_3_SPAWN
};

var speed: float = 0;
var hit: bool = false;

func _init(lane: int):
	position = positionSelector[lane];
	$AnimatedSprite2D.frame = lane;
	speed = DIST_TO_TARGET / 2.0;
	
func _physics_process(delta: float) -> void:
	if (!hit):
		position.y += speed * delta;
		if position.y > TARGET_Y + 20:
			queue_free();
	pass

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
