extends BaseDeath


func enter() -> void:
	base_body.velocity = Vector2.ZERO
	base_body.set_process_input(false)
	base_body.set_physics_process(false)
	var fsm := base_body.get_node_or_null("FSM")
	if fsm != null:
		fsm.set_process(false)
	await base_body.play_animation(animation)
