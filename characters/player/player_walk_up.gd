extends WalkUp

func update(delta: float):
	super.update(delta)
	if Input.is_action_just_released("move_up"):
		transition.emit(self, "idle_up")
	elif Input.is_action_pressed("move_left"):
		xDirection = -1
	elif Input.is_action_pressed("move_right"):
		xDirection = 1
