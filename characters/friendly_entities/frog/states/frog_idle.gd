extends BaseIdle

@onready var timer = $"../../StateTimer"

func enter():
	super.enter()
	
	timer.start(randf_range(0.5, 4.5))
	timer.timeout.connect(random_state_change)
	
func random_state_change():
	timer.timeout.disconnect(random_state_change)
	var state = "idle"
	
	if randf() < 0.5:
		state = "walk"
		
	var states = get_possible_states()
	var next_state = states[randi() % states.size()]
	
	transition.emit(self, next_state)
	
func get_possible_states() -> Array:
	var states = []
	var current_state_form = name.split("_")
	var current_base = current_state_form[0]
	var current_direction = current_state_form[1]
	
	for base in ["idle", "walk"]:
		for direction in ["left", "right", "down", "up"]:
			if base == "walk" && current_direction != direction:
				continue
			if base == current_base && direction == current_direction:
				continue

			states.push_back(base + "_" + direction)
	return states
