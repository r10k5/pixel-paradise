extends WalkUp

func update(delta: float):
	if Input.is_action_just_pressed("attack"):
		var tool_state := (base_body as Player).get_tool_attack_state(name)
		if not tool_state.is_empty():
			transition.emit(self, tool_state)
			return
	if Input.is_action_just_pressed("jump"):
		transition.emit(self, Player.jump_state_for(name))
		return
	super.update(delta)
	if Input.is_action_just_released("move_up"):
		transition.emit(self, "idle_up")
	elif Input.is_action_pressed("move_left"):
		xDirection = -1
	elif Input.is_action_pressed("move_right"):
		xDirection = 1
