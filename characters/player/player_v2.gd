extends BaseBody

class_name Player

var inventory: Inventory = Inventory.new()

func _ready():
	animations = {
		"idle_right": "idle_right",
		"idle_left": "idle_left",
		"idle_up": "idle_up",
		"idle_down": "idle_down",
		"walk_up": "walk_up",
		"walk_left": "walk_left",
		"walk_right": "walk_right",
		"walk_down": "walk_down",
		"death_right": "death_right",
		"death_left": "death_left",
		"death_up": "death_up",
		"death_down": "death_down",
	}

func use():
	if Input.is_action_just_pressed("use"):
		take_damage(health)

func _physics_process(_delta: float):
	use()
	move_and_slide()
