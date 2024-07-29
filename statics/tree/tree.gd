extends BaseEntity

const LOG = preload("res://statics/drop/log.tscn")

func _ready():
	super._ready()
	id = "passive-entity:tree"
	max_health = 10
	health = max_health
	drops = [LOG.instantiate()]
	animations = {}
	
func die():
	super.die()
	queue_free()

func interact():
	super.interact()
	take_damage(5)
