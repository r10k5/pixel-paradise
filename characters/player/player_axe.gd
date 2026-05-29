extends BaseAxe

func _get_attack_direction() -> Vector2:
	match name:
		"axe_up":
			return Vector2.UP
		"axe_down":
			return Vector2.DOWN
		_:
			return Vector2.LEFT if base_body.facing_left else Vector2.RIGHT

func _return_to_movement() -> void:
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
	else:
		transition.emit(self, return_idle_state)
