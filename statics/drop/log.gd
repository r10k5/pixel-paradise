extends BaseEntity

func _init() -> void:
	id = "item:log"
	title = "Бревно"
	max_health = 1
	health = max_health
	can_be_destroyed = false
	effects = []
	effects_can_be_applied = {}
	pick_up_trigger = PickUpTrigger.Auto
	texture = PickupIcons.get_texture("item:log")

func _ready() -> void:
	super._ready()
