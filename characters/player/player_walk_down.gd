extends WalkDown

func update(delta: float):
	if Input.is_action_just_pressed("jump"):
		transition.emit(self, Player.jump_state_for(name))
		return
	super.update(delta)
	if Input.is_action_just_released("move_down"):
		transition.emit(self, "idle_down")
	elif Input.is_action_pressed("move_left"):
		xDirection = -1
	elif Input.is_action_pressed("move_right"):
		xDirection = 1
