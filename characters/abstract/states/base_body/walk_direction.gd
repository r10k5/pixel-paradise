extends State

class_name WalkDirection

@export var base_body: BaseBody
@export var left_animation: String
@export var right_animation: String
@export var up_animation: String
@export var down_animation: String
@export var direction: Vector2 = Vector2(-1, 0)

var current_animation = ""

func enter():
	switch_animation()
	
func physics_update(delta: float):
	if base_body:
		base_body.velocity = direction.normalized() * base_body.speed
		
	switch_animation()

func switch_animation():
	var new_animation: String
	
	if direction == Vector2(-1, 0):
		new_animation = left_animation
	if direction == Vector2(1, 0):
		new_animation = right_animation
	if direction == Vector2(0, -1) || direction == Vector2(1, -1) || direction == Vector2(-1, -1):
		new_animation = up_animation
	if direction == Vector2(0, 1) || direction == Vector2(1, 1) || direction == Vector2(-1, 1):
		new_animation = down_animation
		
	if !new_animation:
		new_animation = up_animation
		
	if new_animation == current_animation:
		return
		
	base_body.play_animation(new_animation)
