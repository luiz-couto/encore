extends AnimatedSprite2D

var perfectArea: bool = false;
var goodArea: bool = false;
var okayArea: bool = false;
var currentNote: Area2D = null;

@export
var input: String = "";

func _unhandled_input(event: InputEvent):
	#print(event.as_text())
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
				reset();
			else:
				pass;
		elif (event.is_action_released(input)):
			$PushTimer.start();
			

func _on_push_timer_timeout() -> void:
	frame = 0;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

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
