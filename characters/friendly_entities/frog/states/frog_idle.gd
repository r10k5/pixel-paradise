extends BaseIdle

@onready var timer = $"../../StateTimer"

func enter() -> void:
	super.enter()
	timer.start(randf_range(0.5, 4.5))
	timer.timeout.connect(random_state_change)

func random_state_change() -> void:
	timer.timeout.disconnect(random_state_change)
	var states := get_possible_states()
	if states.is_empty():
		return
	var next_state: String = states[randi() % states.size()]
	if next_state == "walk_side":
		base_body.set_facing_left(randi() % 2 == 0)
	transition.emit(self, next_state)

func get_possible_states() -> Array:
	var states: Array = []
	var parts := name.split("_")
	var current_base: String = parts[0]
	var current_direction: String = parts[1]

	for base in ["idle", "walk"]:
		for direction in ["side", "up", "down"]:
			if base == "walk" and current_direction != direction:
				continue
			if base == current_base and direction == current_direction:
				continue
			states.push_back("%s_%s" % [base, direction])
	return states
