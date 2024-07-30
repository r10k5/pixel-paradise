extends Node

class_name StateMachine

@export var initial_state: State

var current_state: State

var states: Dictionary = {}

func _ready():
	for state in get_children():
		if state is State:
			states[state.name.to_lower()] = state
			state.transition.connect(change_state)
			
	if initial_state:
		initial_state.enter()
		current_state = initial_state
	
func _process(delta: float):
	if current_state:
		current_state.update(delta)
		
func _physics_process(delta):
	if current_state:
		current_state.physics_update(delta)

func force_change_state(new_state_name: String):
	var new_state: State = states.get(new_state_name.to_lower())
	
	if !new_state:
		print("State " + new_state_name + " not found")
		return
		
	if current_state == new_state:
		print("State is same, aborting")
	
	if current_state:
		var exit_callable = Callable(current_state, "exit")
		exit_callable.call_deferred()
	
	new_state.enter()
	current_state = new_state

func change_state(state: State, new_state_name: String):
	if state != current_state:
		return
	
	var new_state = states.get(new_state_name.to_lower())
	
	if !new_state:
		print("State " + new_state_name + " not found")
		return
	
	if current_state:
		current_state.exit()
		
	new_state.enter()
	print("State change from " + current_state.name + " to " + new_state_name)
	current_state = new_state
