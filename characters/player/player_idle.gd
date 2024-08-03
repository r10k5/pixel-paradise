extends BaseIdle

func update(_delta: float):
	if Input.is_action_pressed("move_up"):
		transition.emit(self, "walk_up")
	elif Input.is_action_pressed("move_down"):
		transition.emit(self, "walk_down")
	elif Input.is_action_pressed("move_left"):
		transition.emit(self, "walk_left")
	elif Input.is_action_pressed("move_right"):
		transition.emit(self, "walk_right")
