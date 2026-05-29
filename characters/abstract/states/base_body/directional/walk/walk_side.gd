extends State

class_name WalkSide

@export var base_body: BaseBody
@export var animation: String = "walk_right"

func enter() -> void:
	base_body.death.connect(_on_death)
	base_body.play_animation(animation)

func _on_death() -> void:
	transition.emit(self, "death_side")

func exit() -> void:
	base_body.death.disconnect(_on_death)

func update(_delta: float) -> void:
	var h := Input.get_axis(&"move_left", &"move_right")
	if h < 0.0:
		base_body.set_facing_left(true)
	elif h > 0.0:
		base_body.set_facing_left(false)
	if h != 0.0:
		base_body.velocity = Vector2(h, 0.0).normalized() * base_body.speed
	else:
		base_body.velocity = Vector2.ZERO
