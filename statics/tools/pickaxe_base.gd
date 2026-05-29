extends BaseEntity

func _init() -> void:
	id = "item:pickaxe"
	title = "Кирка"
	max_health = 1
	health = max_health
	can_be_destroyed = false
	pick_up_trigger = PickUpTrigger.None

func _ready() -> void:
	super._ready()
