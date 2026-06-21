extends AnimatedSprite2D

const HIT_BUTTON_Y: float = 713.0

var perfectArea: bool = false;
var goodArea: bool = false;
var okayArea: bool = false;
var currentNote: Area2D = null;

@export var input: String = ""
@export var laneFlash: ColorRect

const LANE_FLASH_ALPHA: float = 0.55
const LANE_FLASH_DURATION: float = 0.18
const LANE_NUDGE_PIXELS: float = 10.0
const LANE_NUDGE_DOWN_DURATION: float = 0.04
const LANE_NUDGE_UP_DURATION: float = 0.1
const LANE_SHAKE_PIXELS: float = 6.0
const LANE_SHAKE_STEPS: int = 6
const LANE_SHAKE_DURATION: float = 0.12

var _flashTween: Tween = null
var _nudgeTween: Tween = null
var _shakeTween: Tween = null
var _originalOffsetTop: float = 0.0
var _originalOffsetBottom: float = 0.0
var _originalOffsetLeft: float = 0.0
var _originalOffsetRight: float = 0.0

func _play_lane_flash() -> void:
	if laneFlash == null:
		return
	if _flashTween:
		_flashTween.kill()
	if _nudgeTween:
		_nudgeTween.kill()
		laneFlash.offset_top = _originalOffsetTop
		laneFlash.offset_bottom = _originalOffsetBottom
	if _shakeTween:
		_shakeTween.kill()
		laneFlash.offset_left = _originalOffsetLeft
		laneFlash.offset_right = _originalOffsetRight
	laneFlash.color.a = LANE_FLASH_ALPHA
	_flashTween = create_tween()
	_flashTween.tween_property(laneFlash, "color:a", 0.0, LANE_FLASH_DURATION)
	_nudgeTween = create_tween()
	_nudgeTween.tween_property(laneFlash, "offset_top", _originalOffsetTop + LANE_NUDGE_PIXELS, LANE_NUDGE_DOWN_DURATION)
	_nudgeTween.parallel().tween_property(laneFlash, "offset_bottom", _originalOffsetBottom + LANE_NUDGE_PIXELS, LANE_NUDGE_DOWN_DURATION)
	_nudgeTween.tween_property(laneFlash, "offset_top", _originalOffsetTop, LANE_NUDGE_UP_DURATION)
	_nudgeTween.parallel().tween_property(laneFlash, "offset_bottom", _originalOffsetBottom, LANE_NUDGE_UP_DURATION)
	_shakeTween = create_tween()
	for i in LANE_SHAKE_STEPS:
		var jitter = randf_range(-LANE_SHAKE_PIXELS, LANE_SHAKE_PIXELS)
		_shakeTween.tween_property(laneFlash, "offset_left", _originalOffsetLeft + jitter, LANE_SHAKE_DURATION / LANE_SHAKE_STEPS)
		_shakeTween.parallel().tween_property(laneFlash, "offset_right", _originalOffsetRight + jitter, LANE_SHAKE_DURATION / LANE_SHAKE_STEPS)
	_shakeTween.tween_property(laneFlash, "offset_left", _originalOffsetLeft, 0.03)
	_shakeTween.parallel().tween_property(laneFlash, "offset_right", _originalOffsetRight, 0.03)

func _unhandled_input(event: InputEvent):
	if (event.is_action(input)):
		if (event.is_action_pressed(input, false)):
			frame = 1;
			if (currentNote != null):
				if (perfectArea):
					currentNote.destroy(3);
				elif (goodArea):
					currentNote.destroy(2);
				elif (okayArea):
					currentNote.destroy(1);
				_play_lane_flash()
				reset();
			else:
				pass;
		elif (event.is_action_released(input)):
			$PushTimer.start();
			

func _on_push_timer_timeout() -> void:
	frame = 0;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if laneFlash != null:
		_originalOffsetTop = laneFlash.offset_top
		_originalOffsetBottom = laneFlash.offset_bottom
		_originalOffsetLeft = laneFlash.offset_left
		_originalOffsetRight = laneFlash.offset_right

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _on_perfect_area_entered(area: Area2D) -> void:
	if (area.is_in_group("note")):
		perfectArea = true;
		

func _on_perfect_area_exited(area: Area2D) -> void:
	if (area.is_in_group("note")):
		perfectArea = false;

func _on_good_area_entered(area: Area2D) -> void:
	if (area.is_in_group("note")):
		goodArea = true;

func _on_good_area_exited(area: Area2D) -> void:
	if (area.is_in_group("note")):
		goodArea = false;

func _on_okay_area_entered(area: Area2D) -> void:
	if (area.is_in_group("note")):
		okayArea = true;
		currentNote = area;

func _on_okay_area_exited(area: Area2D) -> void:
	if (area.is_in_group("note")):
		okayArea = false;
		currentNote = null;

func reset() -> void:
	currentNote = null;
	perfectArea = false;
	goodArea = false;
	okayArea = false;
