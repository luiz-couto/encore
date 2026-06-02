extends AnimatedSprite2D

var perfectArea: bool = false;
var goodArea: bool = false;
var okayArea: bool = false;

@export
var input: String = "";

func _unhandled_input(event: InputEvent):
	#print(event.as_text())
	if (event.is_action(input)):
		if (event.is_action_pressed(input, false)):
			frame = 1;
		elif (event.is_action_released(input)):
			$PushTimer.start();
			

func _on_push_timer_timeout() -> void:
	frame = 0;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
