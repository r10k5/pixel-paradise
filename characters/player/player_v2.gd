extends BaseBody

class_name Player

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
	
func motion(_delta: float):
	var motion_vector = Vector2()
	
	if Input.is_action_pressed("move_down"):
		motion_vector.y += 1
	if Input.is_action_pressed("move_up"):
		motion_vector.y += -1
	if Input.is_action_pressed("move_left"):
		motion_vector.x += -1
	if Input.is_action_pressed("move_right"):
		motion_vector.x += 1
		
	velocity = motion_vector.normalized() * speed

func use():
	if Input.is_action_just_pressed("use"):
		take_damage(health)

func _physics_process(delta: float):
	motion(delta)
	use()
	move_and_slide()
