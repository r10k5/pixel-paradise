extends BaseBody

class_name Player

@onready var clothes = $AnimatedSprite2D2
const STEPS_SOUND := preload("res://sound/steps.wav")
const MIN_STEP_SPEED := 20.0
var inventory: Inventory = Inventory.new()
var clothes_animations = {
	"idle_right": "right",
	"idle_left": "left",
	"idle_up": "up",
	"idle_down": "down",
}
var _steps_player: AudioStreamPlayer
var _was_moving: bool = false

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
	_setup_steps_player()
	

func on_animation_change(animation_name: String):
	if animation_name in clothes_animations:
		var animation = clothes_animations[animation_name]
		clothes.play(animation)

func use():
	if Input.is_action_just_pressed("use"):
		#take_damage(health)
		pass

func _physics_process(_delta: float):
	use()
	move_and_slide()
	_process_steps(_delta)

func _setup_steps_player() -> void:
	_steps_player = AudioStreamPlayer.new()
	_steps_player.name = "StepsAudio"
	_steps_player.stream = STEPS_SOUND
	_steps_player.bus = "Master"
	_steps_player.volume_db = -10.0
	add_child(_steps_player)

func _process_steps(delta: float) -> void:
	if _steps_player == null:
		return
	var _unused := delta
	var is_moving := velocity.length() >= MIN_STEP_SPEED

	if is_moving and not _was_moving:
		_steps_player.pitch_scale = randf_range(0.95, 1.08)
		_steps_player.play()
	elif not is_moving and _was_moving:
		_steps_player.stop()

	_was_moving = is_moving
