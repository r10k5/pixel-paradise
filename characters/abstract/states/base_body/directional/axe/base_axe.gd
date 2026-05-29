extends State

class_name BaseAxe

@export var base_body: BaseBody
@export var animation: String
@export var return_idle_state: String = "idle_up"

const HIT_FRAME_START := 2
const HIT_FRAME_END := 4

var _sprite: AnimatedSprite2D
var _axe_hit_area: Area2D
var _axe_collision: CollisionShape2D
var _axe_collision_base_x: float
var _hit_entities: Array[BaseEntity] = []

func enter() -> void:
	_hit_entities.clear()
	base_body.velocity = Vector2.ZERO
	base_body.death.connect(_on_death)
	_sprite = base_body.get_node("AnimatedSprite2D") as AnimatedSprite2D
	_axe_hit_area = base_body.find_child("AxeHitArea", true, false) as Area2D
	_axe_collision = base_body.find_child("AxeCollision", true, false) as CollisionShape2D
	if _axe_collision:
		_axe_collision_base_x = absf(_axe_collision.position.x)
	_set_axe_collision(false)
	if _axe_hit_area:
		_axe_hit_area.body_entered.connect(_on_axe_body_entered)
	if _sprite:
		_sprite.frame_changed.connect(_on_frame_changed)
		_update_axe_collision()
	await base_body.play_animation(animation)
	_return_to_movement()

func exit() -> void:
	_set_axe_collision(false)
	if _axe_hit_area and _axe_hit_area.body_entered.is_connected(_on_axe_body_entered):
		_axe_hit_area.body_entered.disconnect(_on_axe_body_entered)
	if _sprite and _sprite.frame_changed.is_connected(_on_frame_changed):
		_sprite.frame_changed.disconnect(_on_frame_changed)
	if base_body.death.is_connected(_on_death):
		base_body.death.disconnect(_on_death)

func _on_frame_changed() -> void:
	_update_axe_collision()

func _update_axe_collision() -> void:
	if _axe_collision == null or _sprite == null:
		return
	var active := animation == "axe_right" \
		and _sprite.frame >= HIT_FRAME_START \
		and _sprite.frame <= HIT_FRAME_END
	_axe_collision.position.x = -_axe_collision_base_x if base_body.facing_left else _axe_collision_base_x
	_set_axe_collision(active)
	if active:
		_apply_axe_hits()

func _set_axe_collision(enabled: bool) -> void:
	if _axe_collision:
		_axe_collision.disabled = not enabled

func _on_axe_body_entered(body: Node2D) -> void:
	if _axe_collision == null or _axe_collision.disabled:
		return
	_try_damage_choppable(body)

func _apply_axe_hits() -> void:
	if _axe_hit_area == null:
		return
	for body in _axe_hit_area.get_overlapping_bodies():
		_try_damage_choppable(body)

func _try_damage_choppable(body: Node) -> void:
	if not body is BaseEntity or not body.is_in_group("choppable"):
		return
	var entity := body as BaseEntity
	if not entity.can_be_destroyed or entity.health <= 0:
		return
	if entity in _hit_entities:
		return
	_hit_entities.append(entity)
	entity.take_damage(1)

func _on_death() -> void:
	transition.emit(self, _death_state_name())

func _death_state_name() -> String:
	match name:
		"axe_up":
			return "death_up"
		"axe_down":
			return "death_down"
		_:
			return "death_side"

func _return_to_movement() -> void:
	transition.emit(self, return_idle_state)
