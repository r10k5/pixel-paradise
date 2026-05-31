extends BaseEntity
class_name PickupItem


func _configure(p_id: String, p_title: String, p_stack: int, p_weight: float) -> void:
	id = p_id
	title = p_title
	stack_size = p_stack
	item_weight = p_weight
	max_health = 1
	health = 1
	can_be_destroyed = false
	pick_up_trigger = PickUpTrigger.None
	effects = []
	effects_can_be_applied = {}
