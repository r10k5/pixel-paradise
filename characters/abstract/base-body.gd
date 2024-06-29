extends CharacterBody2D

signal changed_hp(current_health)

enum CharacterState {
	Idle,
	MoveLeft,
	MoveRight,
	MoveUp,
	MoveDown,
	MoveUpLeft,
	MoveUpRight,
	MoveDownLeft,
	MoveDownRight,
}

var _current_state = CharacterState.Idle
var _previous_state = CharacterState.Idle
var _speed = 100.0
var _health = 100
var _max_health = 100
var _min_health = 0
var _effects = []

@onready var _effects_node = $Effects

func remove_effect(effect):
	if effect in _effects:
		print("before", _effects)
		_effects = _effects.filter(
			func(eff):
				return eff.get_id() != effect.get_id()
		)
		print("after", _effects)
		
		if effect in _effects_node.get_children():
			_effects_node.remove_child(effect)

func get_effects():
	return _effects

func accept_effect(effect):
	if 'can_apply' in effect and 'apply' in effect and 'effect_end' in effect:
		if effect.can_apply(self) and effect not in _effects and effect not in _effects_node.get_children():
			effect.apply(self)
			_effects.push_back(effect)
			effect.effect_end.connect(remove_effect)
			_effects_node.add_child(effect)
			
func accept_item(item):
	if 'is_effect' in item:
		if item.is_effect():
			accept_effect(item)

func get_min_health():
	return _min_health

func get_max_health():
	return _max_health
	
func set_max_health(max_health: int) -> bool:
	if max_health < _min_health:
		return false
		
	_max_health = max_health
	
	if _max_health < _health:
		set_health(_max_health)
	
	return true

func get_health():
	return _health
	
func set_health(health: int) -> bool:
	if health < _min_health and health > _max_health:
		return false
		
	_health = health
	changed_hp.emit(_health)
	return true

func has_state(state: CharacterState) -> bool:
	return state == _current_state
	
func map_vector_to_state(vector: Vector2) -> CharacterState:
	if vector.x > 0 and vector.y > 0:
		return CharacterState.MoveDownRight
	
	if vector.x < 0 and vector.y > 0:
		return CharacterState.MoveDownLeft
		
	if vector.x > 0 and vector.y < 0:
		return CharacterState.MoveUpRight
		
	if vector.x < 0 and vector.y < 0:
		return CharacterState.MoveUpLeft
		
	if vector.x > 0:
		return CharacterState.MoveRight
		
	if vector.x < 0:
		return CharacterState.MoveLeft
		
	if vector.y < 0:
		return CharacterState.MoveUp
		
	if vector.y > 0:
		return CharacterState.MoveDown
		
	return CharacterState.Idle

func _map_state_to_vector(state: CharacterState) -> Vector2:
	match state:
		CharacterState.MoveRight:
			return Vector2(1, 0)
		CharacterState.MoveLeft:
			return Vector2(-1, 0)
		CharacterState.MoveUp:
			return Vector2(0, -1)
		CharacterState.MoveDown:
			return Vector2(0, 1)
		CharacterState.MoveUpLeft:
			return Vector2(-1, -1)
		CharacterState.MoveUpRight:
			return Vector2(1, -1)
		CharacterState.MoveDownLeft:
			return Vector2(-1, 1)
		CharacterState.MoveDownRight:
			return Vector2(1, 1)
		_:
			return Vector2(0, 0)
	
func _is_relative_or_exact_up_direction(state: CharacterState) -> bool:
	return state == CharacterState.MoveUp or state == CharacterState.MoveUpLeft or state == CharacterState.MoveUpRight

func _is_relative_or_exact_down_direction(state: CharacterState) -> bool:
	return state == CharacterState.MoveDown or state == CharacterState.MoveDownLeft or state == CharacterState.MoveDownRight
	
func _is_exact_horizontal_direction(state: CharacterState) -> bool:
	return state == CharacterState.MoveLeft or state == CharacterState.MoveRight
	
func _map_state_to_animation_name(state: CharacterState) -> String:
	match state:
		CharacterState.MoveRight, CharacterState.MoveLeft, CharacterState.MoveUpLeft, CharacterState.MoveUpRight, CharacterState.MoveDownLeft, CharacterState.MoveDownRight:
			return "move_horizontal"
		CharacterState.MoveUp:
			return "move_up"
		CharacterState.MoveDown:
			return "move_down"
		CharacterState.Idle when _is_relative_or_exact_up_direction(_previous_state):
			return "idle_up"
		CharacterState.Idle when _is_relative_or_exact_down_direction(_previous_state):
			return "idle_down"
		CharacterState.Idle when _is_exact_horizontal_direction(_previous_state):
			return "idle_horizontal"
		_:
			return "idle_up"
	
func _is_need_to_flip_animation(previous_state: CharacterState) -> bool:
	return (
		has_state(CharacterState.MoveLeft) or 
		has_state(CharacterState.MoveUpLeft) or 
		has_state(CharacterState.MoveDownLeft) or
			(
				has_state(CharacterState.Idle) and
					previous_state == CharacterState.MoveLeft or 
					previous_state == CharacterState.MoveLeft
			)
	)
	
func get_speed() -> float:
	return _speed
	
func set_speed(value: float):
	_speed = value

func change_state(to: CharacterState):
	if to == _current_state:
		return
		
	_previous_state = _current_state
	_current_state = to
	
	$AnimatedSprite2D.play(_map_state_to_animation_name(_current_state))
	$AnimatedSprite2D.flip_h = _is_need_to_flip_animation(_previous_state)
	velocity = _map_state_to_vector(_current_state).normalized() * _speed

func move_up():
	change_state(CharacterState.MoveUp)
	
func move_down():
	change_state(CharacterState.MoveDown)
	
func move_up_right():
	change_state(CharacterState.MoveUpRight)

func move_up_left():
	change_state(CharacterState.MoveUpLeft)
	
func move_down_right():
	change_state(CharacterState.MoveDownRight)

func move_down_left():
	change_state(CharacterState.MoveDownLeft)
	
func move_left():
	change_state(CharacterState.MoveLeft)
	
func move_right():
	change_state(CharacterState.MoveRight)
