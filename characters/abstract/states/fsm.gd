extends Node

class_name StateMachine

signal state_entering(state: State)

@export var initial_state: State

var current_state: State

var states: Dictionary = {}

func _ready() -> void:
	process_physics_priority = -10
	for state in get_children():
		if state is State:
			states[state.name.to_lower()] = state
			state.transition.connect(change_state)

	if initial_state:
		call_deferred("_enter_initial_state")

func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)

func _enter_initial_state() -> void:
	current_state = initial_state
	_enter_state(initial_state)

func _enter_state(state: State) -> void:
	state_entering.emit(state)
	state.enter()

func force_change_state(new_state_name: String) -> void:
	var new_state: State = states.get(new_state_name.to_lower())

	if not new_state:
		print("State " + new_state_name + " not found")
		return

	if current_state == new_state:
		return

	if current_state:
		current_state.exit()

	current_state = new_state
	_enter_state(new_state)

func change_state(state: State, new_state_name: String) -> void:
	if state != current_state:
		return

	var new_state: State = states.get(new_state_name.to_lower())

	if not new_state:
		print("State " + new_state_name + " not found")
		return

	if current_state:
		current_state.exit()

	current_state = new_state
	_enter_state(new_state)
