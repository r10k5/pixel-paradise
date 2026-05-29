extends BaseDeath


func enter() -> void:
	var player := base_body as Player
	if player != null:
		player.is_dead = true
	base_body.velocity = Vector2.ZERO
	base_body.set_process(false)
	base_body.set_process_input(false)
	base_body.set_physics_process(false)
	var fsm := base_body.get_node_or_null("FSM")
	if fsm != null:
		fsm.set_process(false)
	await base_body.play_animation(animation)
	var main := get_tree().current_scene
	if main != null and main.has_method("on_player_died"):
		await main.on_player_died()
