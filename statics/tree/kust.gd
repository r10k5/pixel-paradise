extends BaseEntity

func _ready():
	fade_when_player_behind = true
	super._ready()
	id = "passive-entity:kust"
	max_health = 10

