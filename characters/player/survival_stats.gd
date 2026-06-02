class_name SurvivalStats
extends Node

signal hunger_changed(value: float)
signal stamina_changed(value: float)
signal hp_changed(value: float)
signal state_changed(state: SurvivalState)
signal dying_countdown_changed(remaining_sec: float)
signal dying_finished()

enum SurvivalState { HEALTHY, HUNGRY, EXHAUSTED, DYING }

@export var max_hp: float = 100.0
@export var max_stamina: float = 100.0
@export var max_hunger: float = 100.0

@export var hunger_decay_per_sec: float = 0.15
@export var hunger_sprint_extra_per_sec: float = 1.0
@export var stamina_regen_per_sec: float = 2.5
@export var heavy_weight_threshold: float = 70.0
@export var heavy_stamina_drain_per_sec: float = 2.0
@export var exhausted_speed_multiplier: float = 0.35
@export var sprint_stamina_drain_per_sec: float = 4.0

var hp: float = 100.0
var stamina: float = 100.0
var hunger: float = 100.0
var current_state: SurvivalState = SurvivalState.HEALTHY

var is_sprinting: bool = false
var is_in_hand_tool: bool = false
var is_working: bool = false

var _rest_timer: float = 0.0
var _dying_timer: float = 0.0
var _dying_resolved: bool = false
var _last_dying_seconds_emit: int = -1
var _last_hunger_emit: int = 100
var _last_stamina_emit: int = 100
var _is_near_safe_zone: bool = false
var _safe_zone_check_accum: float = 0.0
const REST_DURATION := 10.0
const REST_HEAL_AMOUNT := 5.0
const DYING_DURATION := 60.0
const HUNGER_BLOCK_STAMINA_REGEN := 30.0
const HUNGER_SLOW_THRESHOLD := 10.0
const CRITICAL_RATIO := 0.2
const SAFE_ZONE_CHECK_INTERVAL := 0.5
const SAFE_ZONE_RADIUS := 64.0
const JUMP_COST := 10.0
const ATTACK_COST := 15.0
const SPRINT_COST := 5.0

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
	_safe_zone_check_accum += delta
	if _safe_zone_check_accum >= SAFE_ZONE_CHECK_INTERVAL:
		_safe_zone_check_accum = 0.0
		_refresh_near_safe_zone()
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
	return stamina >= SPRINT_COST


func can_jump() -> bool:
	return stamina >= JUMP_COST


func can_attack() -> bool:
	return stamina >= ATTACK_COST


func is_exhausted() -> bool:
	return stamina <= 0.0


func get_move_speed_multiplier() -> float:
	var mult := 1.0
	if hunger < HUNGER_SLOW_THRESHOLD:
		mult *= 0.8
	if stamina <= 0.0:
		mult *= exhausted_speed_multiplier
	return mult


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
	if current_state == SurvivalState.DYING and hp > max_hp * CRITICAL_RATIO:
		_exit_dying()


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
	return _is_near_safe_zone


func _refresh_near_safe_zone() -> void:
	_is_near_safe_zone = false
	if _player == null:
		return
	for node in get_tree().get_nodes_in_group("safe_zone"):
		if node is Node2D and _player.global_position.distance_to((node as Node2D).global_position) <= SAFE_ZONE_RADIUS:
			_is_near_safe_zone = true
			return


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
	if not _player.velocity.is_zero_approx():
		_rest_timer = 0.0
		return
	if not _is_near_safe_zone:
		_rest_timer = 0.0
		return
	_rest_timer += delta
	if _rest_timer >= REST_DURATION:
		heal(REST_HEAL_AMOUNT)
		_rest_timer = 0.0


func get_dying_time_remaining() -> float:
	return maxf(0.0, _dying_timer)


func revive_to_full() -> void:
	hp = max_hp
	stamina = max_stamina
	hunger = max_hunger
	_dying_resolved = true
	_exit_dying()
	sync_display()
	save()


func _tick_dying(delta: float) -> void:
	if current_state != SurvivalState.DYING:
		return
	_dying_timer -= delta
	_emit_dying_countdown_if_changed()
	if _dying_timer <= 0.0 and not _dying_resolved:
		_dying_resolved = true
		dying_finished.emit()


func _emit_dying_countdown_if_changed() -> void:
	var seconds_left := int(ceil(_dying_timer))
	if seconds_left == _last_dying_seconds_emit:
		return
	_last_dying_seconds_emit = seconds_left
	dying_countdown_changed.emit(_dying_timer)


func _enter_dying() -> void:
	if current_state == SurvivalState.DYING:
		return
	current_state = SurvivalState.DYING
	_dying_timer = DYING_DURATION
	_dying_resolved = false
	_last_dying_seconds_emit = -1
	state_changed.emit(current_state)
	_emit_dying_countdown_if_changed()
	if _player != null and not _player.is_dead:
		_player.velocity = Vector2.ZERO
		_player.death.emit()


func _exit_dying() -> void:
	if current_state != SurvivalState.DYING:
		return
	_dying_timer = 0.0
	_last_dying_seconds_emit = -1
	current_state = SurvivalState.HEALTHY
	state_changed.emit(current_state)


func _update_state() -> void:
	var new_state := SurvivalState.HEALTHY

	if current_state == SurvivalState.DYING and hp <= max_hp * CRITICAL_RATIO:
		new_state = SurvivalState.DYING
	elif stamina <= 0.0:
		new_state = SurvivalState.EXHAUSTED
	elif hunger < HUNGER_BLOCK_STAMINA_REGEN or hp < max_hp * CRITICAL_RATIO:
		new_state = SurvivalState.HUNGRY
	else:
		new_state = SurvivalState.HEALTHY

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
