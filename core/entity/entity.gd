extends CharacterBody2D

class_name BaseEntity

signal drop_item(item)
signal drop_effect(item)
signal death()
signal health_changed(value: int)
signal pick_up(entity: BaseEntity)
signal animation_change(name: String)

enum PickUpTrigger {
	Auto,
	Manual,
	None
}

var id = null
var title = ""
var max_health: int = 100
var health: int = max_health
var can_be_destroyed: bool = true
var pick_up_trigger: PickUpTrigger = PickUpTrigger.None
var drops: Array = []
var effects: Array = []
var animations: Dictionary = {}
var effects_can_be_applied: Dictionary = {}
@export var texture: Texture

## Смещение «линии земли» для YSort (если включён на родителе).
@export var depth_sort_feet_bias: float = 14.0
## Делать объект полупрозрачным, когда игрок "за" его спрайтом.
@export var fade_when_player_behind: bool = false
@export var behind_fade_alpha: float = 0.45
@export var behind_fade_speed: float = 8.0
var is_near_player: bool = false
var can_interact: bool = true
var entities_near: Array = []
var _player_cache: Node2D
var _fade_sprite: AnimatedSprite2D
var _fade_sprite_rect: Rect2 = Rect2(Vector2(-8, -8), Vector2(16, 16))

func _ready():
	set_process(true)
	set_process_input(true)
	$Area2D.body_entered.connect(_on_body_entered)
	$Area2D.body_exited.connect(_on_body_exited)
	if fade_when_player_behind:
		_fade_sprite = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
		if _fade_sprite != null:
			_fade_sprite_rect = _animated_sprite_local_rect(_fade_sprite)

func _process(delta: float) -> void:
	_update_player_behind_fade(delta)

func take_damage(amount: int):
	if can_be_destroyed:
		health -= amount
		health_changed.emit(health)
		if health <= 0:
			die()

func die():
	if can_be_destroyed:
		drop_items()
		death.emit()

func drop_items():
	for drop in drops:
		drop_item.emit(drop)
		
func drop_effects():
	for effect in effects:
		drop_effect.emit(effect)

func play_animation(animation_name: String):
	if animation_name in animations:
		$AnimatedSprite2D.play(animations[animation_name])
		animation_change.emit(animation_name)
		return $AnimatedSprite2D.animation_finished

func apply_effect(effect):
	if (
		effect not in $Effects.get_children() and
		effect.id in effects_can_be_applied.keys()
	):
		$Effects.add_child(effect)

func _input(event):
	if event.is_action_pressed("interact") and is_near_player and can_interact:
		interact()
		
	if event.is_action_pressed("pick_up") and pick_up_trigger == PickUpTrigger.Manual:
		on_pick_up()

func on_pick_up():
	pick_up.emit(self)
	# Логика поднятия объекта
	pass

func interact():
	# Логика взаимодействия с объектом
	pass

func _on_Player_nearby(state: bool):
	is_near_player = state
	
func _on_body_entered(body):
	if body not in entities_near:
		entities_near.push_back(body)
		
	if pick_up_trigger == PickUpTrigger.Auto:
		on_pick_up()
		
	if body.name.to_lower() == "player":
		_player_cache = body as Node2D
		_on_Player_nearby(true)

func _on_body_exited(body):
	if body in entities_near:
		entities_near = entities_near.filter(
			func(entity): return entity != body
		)

	if body.name.to_lower() == "player":
		_player_cache = null
		_on_Player_nearby(false)

func _update_player_behind_fade(delta: float) -> void:
	if not fade_when_player_behind:
		_set_sprite_alpha_towards(1.0, delta)
		return
	if not is_near_player:
		_set_sprite_alpha_towards(1.0, delta)
		return
	var sprite := _fade_sprite
	if sprite == null:
		sprite = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
		_fade_sprite = sprite
		if sprite != null:
			_fade_sprite_rect = _animated_sprite_local_rect(sprite)
	if sprite == null:
		return
	var player := _get_player_node()
	if player == null:
		_set_sprite_alpha_towards(1.0, delta)
		return

	var local_player := sprite.to_local(player.global_position)
	var inside_texture: bool = _fade_sprite_rect.has_point(local_player)
	var player_behind: bool = player.global_position.y < global_position.y + depth_sort_feet_bias
	var target_alpha := behind_fade_alpha if (inside_texture and player_behind) else 1.0
	_set_sprite_alpha_towards(target_alpha, delta)

func _set_sprite_alpha_towards(target_alpha: float, delta: float) -> void:
	var sprite := get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite == null:
		return
	var c := sprite.modulate
	c.a = move_toward(c.a, clampf(target_alpha, 0.05, 1.0), behind_fade_speed * delta)
	sprite.modulate = c

func _get_player_node() -> Node2D:
	if is_instance_valid(_player_cache):
		return _player_cache
	var root := get_tree().get_root()
	if root == null:
		return null
	var found := root.find_child("Player", true, false) as Node2D
	_player_cache = found
	return _player_cache

func _animated_sprite_local_rect(sprite: AnimatedSprite2D) -> Rect2:
	var frames := sprite.sprite_frames
	if frames == null:
		return Rect2(Vector2(-8, -8), Vector2(16, 16))
	var anim: StringName = sprite.animation
	var frame_idx := maxi(sprite.frame, 0)
	var tex := frames.get_frame_texture(anim, frame_idx)
	if tex == null:
		return Rect2(Vector2(-8, -8), Vector2(16, 16))
	var size: Vector2 = tex.get_size()
	var top_left := sprite.offset
	if sprite.centered:
		top_left -= size * 0.5
	return Rect2(top_left, size)
