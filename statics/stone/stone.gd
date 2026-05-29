extends BaseEntity

func _ready() -> void:
	add_to_group("mineable")
	super._ready()
	id = "passive-entity:stone"
	max_health = 5
	health = max_health
	can_be_destroyed = true
	animations = {}

func die() -> void:
	super.die()
	queue_free()
