extends Node2D

const NoteScene := preload("res://scenes/note.tscn");

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Conductor.play();

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_timer_timeout() -> void:
	#spawnNote();
	pass;

func _on_conductor_measure(position: int) -> void:
	spawnNote();

func spawnNote() -> void:
	var noteInstance = NoteScene.instantiate();
	noteInstance.initialize(randi() % 4);
	add_child(noteInstance);
