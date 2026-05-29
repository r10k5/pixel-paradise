extends BaseBody

func _ready() -> void:
	super._ready()
	id = "friendly-entity:frog"
	title = "frog"
	max_health = 25
	health = max_health
	can_be_destroyed = true
	drops = []
	effects = []
	speed = 40
	animations = {
		"idle_up": "idle_up",
		"idle_down": "idle_down",
		"idle_right": "idle_right",
		"walk_up": "jump_up",
		"walk_right": "jump_right",
		"walk_down": "jump_down",
	}
	effects_can_be_applied = {}
	can_interact = false

func _physics_process(_delta: float) -> void:
	move_and_slide()
