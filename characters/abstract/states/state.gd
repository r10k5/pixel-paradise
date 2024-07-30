extends Node

class_name State

signal transition(state: State, new_state_name: String)

var fsm: StateMachine

func enter():
	pass
	
func exit():
	pass
	
func update(_delta: float):
	pass
	
func physics_update(_delta: float):
	pass
