extends BaseEntity

func _ready():
	super._ready()
	id = "passive-entity:mushroom"
	title = "Гриб"
	max_health = 1
	health = max_health
	can_be_destroyed = false
	effects = []
	effects_can_be_applied = {}
	pick_up_trigger = PickUpTrigger.Auto