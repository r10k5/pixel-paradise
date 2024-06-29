extends "res://characters/abstract/item.gd"

signal effect_end(effect)

var _id = 0
var _timeout = null
var _can_be_removed_after = null

func _init():
	set_item_type(ItemType.Effect)

func _ready():
	if _timeout:
		get_tree().create_timer(_timeout).timeout.connect(
			func():
				effect_end.emit(self)
		)

func _process(_delta):
	if _can_be_removed_after and 'call' in _can_be_removed_after:
		if _can_be_removed_after.call(self):
			effect_end.emit()

func get_id():
	return _id
	
func set_id(id: int):
	_id = id
	
func can_be_removed_after(predicate):
	if 'call' in predicate:
		_can_be_removed_after = predicate
		_timeout = null
		
func use_timeout(time: float):
	_timeout = time
	_can_be_removed_after = null
	
func can_apply(entity):
	if 'get_effects' in entity:
		var effects = entity.get_effects()
		
		if typeof(effects) == TYPE_ARRAY:
			print(effects)
			var filtered = effects.filter(func(eff): return eff.get_id() == get_id())
			
			return len(filtered) == 0
			
	return false
