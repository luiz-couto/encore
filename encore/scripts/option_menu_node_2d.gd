extends Node2D



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_option_1_mouse_entered() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)


func _on_option_1_mouse_exited() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	

func _on_option_2_mouse_entered() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)


func _on_option_2_mouse_exited() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)


func _on_option_3_mouse_entered() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)

func _on_option_3_mouse_exited() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)

func set_option_1_label(newText: String) -> void:
	$Option1/Label.text = newText
	
func set_option_2_label(newText: String) -> void:
	$Option2/Label.text = newText

func set_option_3_label(newText: String) -> void:
	$Option3/Label.text = newText
