extends PointLight2D

func _input(event):
	if Input.is_action_just_pressed("use"):
		enabled = !enabled
