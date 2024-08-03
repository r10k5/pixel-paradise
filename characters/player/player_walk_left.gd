extends WalkLeft

func update(delta: float):
	super.update(delta)
	if Input.is_action_just_released("move_left"):
		transition.emit(self, "idle_left")
	elif Input.is_action_pressed("move_down"):
		transition.emit(self, "walk_down")
	elif Input.is_action_pressed("move_up"):
		transition.emit(self, "walk_up")
