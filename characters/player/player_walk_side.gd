extends WalkSide

func physics_update(delta: float) -> void:
	super.physics_update(delta)

func update(delta: float) -> void:
	var player := base_body as Player
	var h := Input.get_axis(&"move_left", &"move_right")
	if h != 0.0:
		if Input.is_action_just_pressed("attack"):
			if player.survival != null and not player.survival.can_attack():
				return
			var tool_state := player.get_tool_attack_state(name)
			if not tool_state.is_empty():
				transition.emit(self, tool_state)
				return
		if Input.is_action_just_pressed("jump"):
			if player.survival != null and not player.survival.can_jump():
				return
			transition.emit(self, Player.jump_state_for(name))
		return

	if Input.is_action_pressed("move_up"):
		transition.emit(self, "walk_up")
	elif Input.is_action_pressed("move_down"):
		transition.emit(self, "walk_down")
	else:
		transition.emit(self, "idle_side")
