extends State

class_name BaseHandTool

@export var base_body: BaseBody
@export var animation: String
@export var return_idle_state: String = "idle_up"
@export var target_group: String = "choppable"
@export var hit_damage: int = 1

const HIT_FRAME_START := 2
const HIT_FRAME_END := 4
const HAND_TOOL_SIDE_OFFSET := Vector2(28, -8)

var _sprite: AnimatedSprite2D
var _tool_hit_area: Area2D
var _tool_collision: CollisionShape2D
var _tool_collision_active := false
var _attack_active: bool = false
var _hit_entities: Array[BaseEntity] = []

func enter() -> void:
	_attack_active = false
	if base_body is Player:
		var player := base_body as Player
		var stats := player.get_node_or_null("SurvivalStats") as SurvivalStats
		if stats != null:
			if not stats.can_attack() or not stats.spend_stamina(SurvivalStats.ATTACK_COST):
				transition.emit(self, return_idle_state)
				return
			stats.is_in_hand_tool = true
	_attack_active = true
	_hit_entities.clear()
	base_body.velocity = Vector2.ZERO
	base_body.death.connect(_on_death)
	_sprite = base_body.get_node("AnimatedSprite2D") as AnimatedSprite2D
	_tool_hit_area = base_body.find_child("HandToolHitArea", true, false) as Area2D
	_tool_collision = base_body.find_child("HandToolCollision", true, false) as CollisionShape2D
	_reset_tool_collision_position()
	_set_tool_collision(false)
	if _tool_hit_area:
		_tool_hit_area.body_entered.connect(_on_tool_body_entered)
	if _sprite:
		_sprite.frame_changed.connect(_on_frame_changed)
		_update_tool_collision()
	_connect_attack_finished()
	base_body.play_animation(animation)

func exit() -> void:
	_attack_active = false
	_disconnect_attack_finished()
	if base_body is Player:
		var stats := (base_body as Player).get_node_or_null("SurvivalStats") as SurvivalStats
		if stats != null:
			stats.is_in_hand_tool = false
	_tool_collision_active = false
	_set_tool_collision(false)
	_reset_tool_collision_position()
	if _tool_hit_area and _tool_hit_area.body_entered.is_connected(_on_tool_body_entered):
		_tool_hit_area.body_entered.disconnect(_on_tool_body_entered)
	if _sprite and _sprite.frame_changed.is_connected(_on_frame_changed):
		_sprite.frame_changed.disconnect(_on_frame_changed)
	if base_body.death.is_connected(_on_death):
		base_body.death.disconnect(_on_death)

func _connect_attack_finished() -> void:
	if _sprite == null:
		return
	if _sprite.animation_finished.is_connected(_on_attack_animation_finished):
		_sprite.animation_finished.disconnect(_on_attack_animation_finished)
	_sprite.animation_finished.connect(_on_attack_animation_finished, CONNECT_ONE_SHOT)

func _disconnect_attack_finished() -> void:
	if _sprite != null and _sprite.animation_finished.is_connected(_on_attack_animation_finished):
		_sprite.animation_finished.disconnect(_on_attack_animation_finished)

func _on_attack_animation_finished() -> void:
	if not _attack_active:
		return
	_return_to_movement()

func _on_frame_changed() -> void:
	_update_tool_collision()

func _update_tool_collision() -> void:
	if _tool_collision == null or _sprite == null:
		return
	var on_hit_frame := _sprite.frame >= HIT_FRAME_START and _sprite.frame <= HIT_FRAME_END
	var active := on_hit_frame and _is_hand_tool_state()
	_position_tool_collision()
	_tool_collision_active = active
	_set_tool_collision(active)
	if active:
		_apply_tool_hits()

func _is_hand_tool_state() -> bool:
	return name.begins_with("axe_") or name.begins_with("pickaxe_")

func _get_tool_direction() -> String:
	if name.ends_with("_up"):
		return "up"
	if name.ends_with("_down"):
		return "down"
	return "side"

func _position_tool_collision() -> void:
	var reach := absf(HAND_TOOL_SIDE_OFFSET.x)
	match _get_tool_direction():
		"up":
			_tool_collision.position = Vector2(0, HAND_TOOL_SIDE_OFFSET.y - reach)
		"down":
			_tool_collision.position = Vector2(0, HAND_TOOL_SIDE_OFFSET.y + reach)
		_:
			_tool_collision.position.x = -reach if base_body.facing_left else reach
			_tool_collision.position.y = HAND_TOOL_SIDE_OFFSET.y

func _reset_tool_collision_position() -> void:
	if _tool_collision:
		_tool_collision.position = HAND_TOOL_SIDE_OFFSET

func _set_tool_collision(enabled: bool) -> void:
	if _tool_collision:
		_tool_collision.set_deferred("disabled", not enabled)

func _on_tool_body_entered(body: Node2D) -> void:
	if not _tool_collision_active:
		return
	_queue_tool_damage(body)

func _apply_tool_hits() -> void:
	if _tool_hit_area == null:
		return
	for body in _tool_hit_area.get_overlapping_bodies():
		_queue_tool_damage(body)

func _queue_tool_damage(body: Node) -> void:
	if not body is BaseEntity or not body.is_in_group(target_group):
		return
	var entity := body as BaseEntity
	if not entity.can_be_destroyed or entity.health <= 0:
		return
	if entity in _hit_entities:
		return
	_hit_entities.append(entity)
	DamageAuthority.apply_damage(entity, float(hit_damage), "hand_tool")

func _on_death() -> void:
	transition.emit(self, _death_state_name())

func _death_state_name() -> String:
	match _get_tool_direction():
		"up":
			return "death_up"
		"down":
			return "death_down"
		_:
			return "death_side"

func _return_to_movement() -> void:
	transition.emit(self, return_idle_state)
