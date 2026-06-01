extends WalkDown

func update(delta: float):
	if Input.is_action_just_pressed("attack"):
		var player := base_body as Player
		if player.survival != null and not player.survival.can_attack():
			return
		var tool_state := player.get_tool_attack_state(name)
		if not tool_state.is_empty():
			transition.emit(self, tool_state)
			return
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
