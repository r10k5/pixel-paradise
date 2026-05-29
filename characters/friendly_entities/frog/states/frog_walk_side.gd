extends WalkSide

@onready var timer = $"../../StateTimer"

func enter() -> void:
	super.enter()
	timer.start(0.3)
	timer.timeout.connect(_state_change)

func _state_change() -> void:
	timer.timeout.disconnect(_state_change)
	transition.emit(self, "idle_side")

func update(_delta: float) -> void:
	var direction := -1.0 if base_body.facing_left else 1.0
	base_body.velocity = Vector2(direction, 0.0).normalized() * base_body.speed
