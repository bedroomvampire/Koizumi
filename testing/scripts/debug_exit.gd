extends Node

var input = 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("pause") && OS.is_debug_build():
		get_tree().quit()
	if Input.is_action_just_pressed("`") && OS.is_debug_build():
		if input == 0:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			input = 1
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			input = 0
