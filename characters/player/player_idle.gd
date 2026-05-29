extends BaseIdle

func update(_delta: float) -> void:
	if Input.is_action_just_pressed("attack"):
		var tool_state := (base_body as Player).get_tool_attack_state(name)
		if not tool_state.is_empty():
			transition.emit(self, tool_state)
			return
	if Input.is_action_just_pressed("jump"):
		transition.emit(self, Player.jump_state_for(name))
		return
	if Input.is_action_pressed("move_up"):
		transition.emit(self, "walk_up")
	elif Input.is_action_pressed("move_down"):
		transition.emit(self, "walk_down")
	elif Input.is_action_pressed("move_left"):
		base_body.set_facing_left(true)
		transition.emit(self, "walk_side")
	elif Input.is_action_pressed("move_right"):
		base_body.set_facing_left(false)
		transition.emit(self, "walk_side")
