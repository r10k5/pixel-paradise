extends WalkLeft

@onready var timer = $"../../StateTimer"

func enter():
	super.enter()
	
	timer.start(0.3)
	timer.timeout.connect(state_change)
	
func state_change():
	timer.timeout.disconnect(state_change)
		
	var direction = name.split("_")[1]
	var next_state = "idle_" + direction
	
	transition.emit(self, next_state)
