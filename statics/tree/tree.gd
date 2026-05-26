extends BaseEntity

const LOG = preload("res://statics/drop/log.tscn")

func _ready() -> void:
	depth_sort_feet_bias = 52.0
	super._ready()
	id = "passive-entity:tree"
	max_health = 10
	health = max_health
	drops = [LOG.instantiate()]
	animations = {}


func die() -> void:
	super.die()
	queue_free()


func interact() -> void:
	super.interact()
	take_damage(5)
