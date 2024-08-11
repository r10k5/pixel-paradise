extends BaseBody

class_name Player

@onready var clothes = $AnimatedSprite2D2
var inventory: Inventory = Inventory.new()
var clothes_animations = {
	"idle_right": "right",
	"idle_left": "left",
	"idle_up": "up",
	"idle_down": "down",
}

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
	animation_change.connect(on_animation_change)
	

func on_animation_change(animation_name: String):
	if animation_name in clothes_animations:
		var animation = clothes_animations[animation_name]
		clothes.play(animation)

func use():
	if Input.is_action_just_pressed("use"):
		take_damage(health)

func _physics_process(_delta: float):
	use()
	move_and_slide()
