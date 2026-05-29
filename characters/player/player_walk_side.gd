extends WalkSide

func update(delta: float) -> void:
	if Input.is_action_just_pressed("attack"):
		transition.emit(self, Player.axe_state_for(name))
		return
	if Input.is_action_just_pressed("jump"):
		transition.emit(self, Player.jump_state_for(name))
		return
	super.update(delta)
	if Input.is_action_just_released("move_left") and base_body.facing_left:
		transition.emit(self, "idle_side")
	elif Input.is_action_just_released("move_right") and not base_body.facing_left:
		transition.emit(self, "idle_side")
	elif Input.is_action_pressed("move_up"):
		transition.emit(self, "walk_up")
	elif Input.is_action_pressed("move_down"):
		transition.emit(self, "walk_down")
