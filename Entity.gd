extends CharacterBody2D

var max_health: int = 100
var health: int = max_health
var can_be_destroyed: bool = true
var drops: Array = []
var effects: Array = []
var animations: Dictionary = {}
var status_effects: Dictionary = {}

var is_near_player: bool = false
var can_interact: bool = true

func _ready():
	set_process(true)
	set_process_input(true)
	$Area2D.body_entered.connect(_on_body_entered)
	$Area2D.body_exited.connect(_on_body_exited)

func take_damage(amount: int):
	if can_be_destroyed:
		health -= amount
		if health <= 0:
			die()

func die():
	if can_be_destroyed:
		drop_items()
		play_animation("die")
		queue_free()

func drop_items():
	for drop in drops:
		# Логика для создания и добавления дропа на сцену
		pass

func play_animation(animation_name: String):
	if animation_name in animations:
		$AnimationPlayer.play(animations[animation_name])

func apply_effect(effect_name: String, duration: float):
	# Логика для применения эффекта к сущности
	status_effects[effect_name] = duration
	# Добавьте конкретную логику для каждого эффекта здесь

func _process(delta):
	# Обработка эффектов с течением времени
	for effect in status_effects.keys():
		status_effects[effect] -= delta
		if status_effects[effect] <= 0:
			status_effects.erase(effect)
			# Удалите эффект и примените соответствующие изменения

func _input(event):
	if event.is_action_pressed("interact") and is_near_player and can_interact:
		interact()

func interact():
	# Логика взаимодействия с объектом
	pass

func _on_Player_nearby(state: bool):
	is_near_player = state
	
func _on_body_entered(body):
	if body.name == "Player":
		_on_Player_nearby(true)

func _on_body_exited(body):
	if body.name == "Player":
		_on_Player_nearby(false)
