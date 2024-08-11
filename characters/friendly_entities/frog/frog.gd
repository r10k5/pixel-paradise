extends BaseBody

func _ready():
	super._ready()
	id = "friendly-entity:frog"
	title = "frog"
	max_health = 25
	health= max_health
	can_be_destroyed = true
	drops = []
	effects = []
	speed = 40
	animations = {
		"idle_up": "idle_up",
		"idle_down": "idle_down",
		"idle_left": "idle_left",
		"idle_right": "idle_right",
		"walk_up": "jump_up",
		"walk_right": "jump_right",
		"walk_left": "jump_left",
		"walk_down": "jump_down",
		#"water_down": "water_down",
		#"water_up": "water_up",
		#"water_left": "water_left",
		#"water_right": "water_right"
	}
	effects_can_be_applied = {}
	can_interact = false

func _physics_process(_delta: float):
	move_and_slide()
