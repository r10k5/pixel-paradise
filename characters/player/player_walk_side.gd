extends WalkSide

func update(delta: float) -> void:
	super.update(delta)
	if Input.is_action_just_released("move_left") and base_body.facing_left:
		transition.emit(self, "idle_side")
	elif Input.is_action_just_released("move_right") and not base_body.facing_left:
		transition.emit(self, "idle_side")
	elif Input.is_action_pressed("move_up"):
		transition.emit(self, "walk_up")
	elif Input.is_action_pressed("move_down"):
		transition.emit(self, "walk_down")
