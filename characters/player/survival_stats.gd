class_name SurvivalStats
extends Node

signal hunger_changed(value: float)
signal stamina_changed(value: float)
signal hp_changed(value: float)
signal state_changed(state: SurvivalState)

enum SurvivalState { HEALTHY, HUNGRY, EXHAUSTED, DYING }

@export var max_hp: float = 100.0
@export var max_stamina: float = 100.0
@export var max_hunger: float = 100.0

@export var hunger_decay_per_sec: float = 0.5
@export var hunger_sprint_extra_per_sec: float = 1.0
@export var stamina_regen_per_sec: float = 3.0
@export var heavy_weight_threshold: float = 70.0
@export var heavy_stamina_drain_per_sec: float = 2.0

var hp: float = 100.0
var stamina: float = 100.0
var hunger: float = 100.0
var current_state: SurvivalState = SurvivalState.HEALTHY

var is_sprinting: bool = false
var is_in_hand_tool: bool = false
var is_working: bool = false

var _rest_timer: float = 0.0
var _dying_timer: float = 0.0
var _last_hunger_emit: int = 100
var _last_stamina_emit: int = 100
const REST_DURATION := 10.0
const REST_HEAL_AMOUNT := 5.0
const DYING_DURATION := 60.0
const HUNGER_BLOCK_STAMINA_REGEN := 30.0
const HUNGER_SLOW_THRESHOLD := 10.0
const CRITICAL_RATIO := 0.2

@onready var _player: Player = get_parent() as Player


func _ready() -> void:
	hp = max_hp
	stamina = max_stamina
	hunger = max_hunger
	_last_hunger_emit = int(hunger)
	_last_stamina_emit = int(stamina)
	_emit_all()
	SurvivalPersistence.load(self, PlayerProfile.player_id)
	_last_hunger_emit = int(hunger)
	_last_stamina_emit = int(stamina)


func _physics_process(delta: float) -> void:
	if _player != null and _player.is_dead:
		return
	_tick_hunger(delta)
	_tick_stamina(delta)
	_tick_starvation_damage(delta)
	_tick_rest_heal(delta)
	_tick_dying(delta)
	_update_state()


func is_spending_stamina() -> bool:
	if is_sprinting or is_in_hand_tool or is_working:
		return true
	if _player != null and _player.inventory.get_total_weight() > heavy_weight_threshold:
		return true
	return false


func can_sprint() -> bool:
	return stamina > 0.0


func can_jump() -> bool:
	return stamina > 0.0


func can_attack() -> bool:
	return stamina > 0.0


func get_move_speed_multiplier() -> float:
	if hunger < HUNGER_SLOW_THRESHOLD:
		return 0.8
	return 1.0


func apply_damage(amount: float) -> void:
	if amount <= 0.0:
		return
	hp = maxf(0.0, hp - amount)
	hp_changed.emit(hp)
	if hp <= 0.0:
		_enter_dying()


func heal(amount: float) -> void:
	if amount <= 0.0:
		return
	hp = minf(max_hp, hp + amount)
	hp_changed.emit(hp)
	if hp > 0.0 and current_state == SurvivalState.DYING:
		current_state = SurvivalState.HEALTHY
		state_changed.emit(current_state)


func restore_hunger(amount: float) -> void:
	hunger = minf(max_hunger, hunger + amount)
	_emit_hunger_if_changed()


func restore_stamina(amount: float) -> void:
	stamina = minf(max_stamina, stamina + amount)
	_emit_stamina_if_changed()


func spend_stamina(amount: float) -> bool:
	if amount <= 0.0:
		return true
	if stamina < amount:
		return false
	stamina -= amount
	_emit_stamina_if_changed()
	return true


func spend_stamina_flat(amount: float) -> void:
	stamina = maxf(0.0, stamina - amount)
	_emit_stamina_if_changed()


func is_near_campfire_or_safe() -> bool:
	if _player == null:
		return false
	for node in get_tree().get_nodes_in_group("campfire"):
		if node is Node2D and _player.global_position.distance_to((node as Node2D).global_position) <= 48.0:
			return true
	for node in get_tree().get_nodes_in_group("safe_zone"):
		if node is Node2D and _player.global_position.distance_to((node as Node2D).global_position) <= 64.0:
			return true
	return false


func _tick_hunger(delta: float) -> void:
	var decay := hunger_decay_per_sec
	if is_sprinting or is_working or is_in_hand_tool:
		decay += hunger_sprint_extra_per_sec
	hunger = maxf(0.0, hunger - decay * delta)
	_emit_hunger_if_changed()


func _tick_stamina(delta: float) -> void:
	if is_spending_stamina():
		return
	if hunger < HUNGER_BLOCK_STAMINA_REGEN:
		return
	stamina = minf(max_stamina, stamina + stamina_regen_per_sec * delta)
	_emit_stamina_if_changed()


func _emit_hunger_if_changed() -> void:
	var displayed := int(hunger)
	if displayed != _last_hunger_emit:
		_last_hunger_emit = displayed
		hunger_changed.emit(hunger)


func _emit_stamina_if_changed() -> void:
	var displayed := int(stamina)
	if displayed != _last_stamina_emit:
		_last_stamina_emit = displayed
		stamina_changed.emit(stamina)


func _tick_starvation_damage(delta: float) -> void:
	if hunger > 0.0:
		return
	apply_damage(2.0 * delta)


func _tick_rest_heal(delta: float) -> void:
	if _player == null:
		return
	if hunger < HUNGER_BLOCK_STAMINA_REGEN:
		_rest_timer = 0.0
		return
	if _player.velocity.length() > 5.0 or is_sprinting or is_in_hand_tool:
		_rest_timer = 0.0
		return
	if not is_near_campfire_or_safe():
		_rest_timer = 0.0
		return
	_rest_timer += delta
	if _rest_timer >= REST_DURATION:
		heal(REST_HEAL_AMOUNT)
		_rest_timer = 0.0


func _tick_dying(_delta: float) -> void:
	pass


func _enter_dying() -> void:
	if current_state == SurvivalState.DYING:
		return
	current_state = SurvivalState.DYING
	_dying_timer = DYING_DURATION
	state_changed.emit(current_state)
	if _player != null and not _player.is_dead:
		_player.velocity = Vector2.ZERO
		_player.death.emit()


func _update_state() -> void:
	var new_state := SurvivalState.HEALTHY
	if current_state == SurvivalState.DYING:
		return
	if hunger < HUNGER_BLOCK_STAMINA_REGEN or hp < max_hp * CRITICAL_RATIO:
		new_state = SurvivalState.HUNGRY
	if stamina <= 0.0:
		new_state = SurvivalState.EXHAUSTED
	if new_state != current_state:
		current_state = new_state
		state_changed.emit(current_state)


func sync_display() -> void:
	hp_changed.emit(hp)
	hunger_changed.emit(hunger)
	stamina_changed.emit(stamina)
	state_changed.emit(current_state)


func _emit_all() -> void:
	sync_display()


func save() -> void:
	SurvivalPersistence.save(self, PlayerProfile.player_id)
