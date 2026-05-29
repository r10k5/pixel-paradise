extends BaseEntity

func _init() -> void:
	id = "item:bomb"
	title = "Бомба"
	max_health = 1
	health = max_health
	can_be_destroyed = false
	pick_up_trigger = PickUpTrigger.Auto

func _ready() -> void:
	super._ready()
