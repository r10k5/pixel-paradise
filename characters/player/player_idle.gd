extends BaseIdle

func update(_delta: float) -> void:
	super.update(_delta)
	var player := base_body as Player
	if Input.is_action_pressed("move_up"):
		transition.emit(self, "walk_up")
		return
	if Input.is_action_pressed("move_down"):
		transition.emit(self, "walk_down")
		return
	if Input.is_action_pressed("move_left"):
		base_body.set_facing_left(true)
		transition.emit(self, "walk_side")
		return
	if Input.is_action_pressed("move_right"):
		base_body.set_facing_left(false)
		transition.emit(self, "walk_side")
		return

	base_body.velocity = Vector2.ZERO

	if Input.is_action_just_pressed("jump"):
		if player.survival != null and not player.survival.can_jump():
			return
		transition.emit(self, Player.jump_state_for(name))
		return
	if Input.is_action_just_pressed("attack"):
		if player.survival != null and not player.survival.can_attack():
			return
		var tool_state := player.get_tool_attack_state(name)
		if not tool_state.is_empty():
			transition.emit(self, tool_state)
