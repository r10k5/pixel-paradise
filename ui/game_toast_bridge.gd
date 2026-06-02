class_name GameToastBridge
extends Node

const CRITICAL_RATIO := 0.2
const RESET_RATIO := 0.25

var _toast: ToastManager
var _stats: SurvivalStats
var _prev_state: SurvivalStats.SurvivalState = SurvivalStats.SurvivalState.HEALTHY
var _warned: Dictionary = {
	"hunger": false,
	"stamina": false,
	"hp": false,
}


func bind(toast: ToastManager, stats: SurvivalStats) -> void:
	if _stats != null:
		unbind()
	_toast = toast
	_stats = stats
	if _stats == null:
		return
	_prev_state = _stats.current_state
	_stats.hunger_changed.connect(_on_hunger_changed)
	_stats.stamina_changed.connect(_on_stamina_changed)
	_stats.hp_changed.connect(_on_hp_changed)
	_stats.state_changed.connect(_on_state_changed)
	_on_hunger_changed(_stats.hunger)
	_on_stamina_changed(_stats.stamina)
	_on_hp_changed(_stats.hp)
	_on_state_changed(_stats.current_state)


func unbind() -> void:
	if _stats == null:
		return
	if _stats.hunger_changed.is_connected(_on_hunger_changed):
		_stats.hunger_changed.disconnect(_on_hunger_changed)
	if _stats.stamina_changed.is_connected(_on_stamina_changed):
		_stats.stamina_changed.disconnect(_on_stamina_changed)
	if _stats.hp_changed.is_connected(_on_hp_changed):
		_stats.hp_changed.disconnect(_on_hp_changed)
	if _stats.state_changed.is_connected(_on_state_changed):
		_stats.state_changed.disconnect(_on_state_changed)
	_stats = null
	_toast = null


func _on_hunger_changed(value: float) -> void:
	_update_warn(
		"hunger",
		value / _stats.max_hunger,
		ToastMessages.hunger_critical()
	)


func _on_stamina_changed(value: float) -> void:
	_update_warn(
		"stamina",
		value / _stats.max_stamina,
		ToastMessages.stamina_low()
	)


func _on_hp_changed(value: float) -> void:
	if _stats.current_state == SurvivalStats.SurvivalState.DYING:
		return
	_update_warn("hp", value / _stats.max_hp, ToastMessages.hp_critical())


func _on_state_changed(state: SurvivalStats.SurvivalState) -> void:
	if state == SurvivalStats.SurvivalState.DYING and _prev_state != SurvivalStats.SurvivalState.DYING:
		ToastMessages.show(_toast, ToastMessages.dying_entered())
		ToastMessages.show(_toast, ToastMessages.dying_timer_hint())
	elif _prev_state == SurvivalStats.SurvivalState.DYING and state != SurvivalStats.SurvivalState.DYING:
		ToastMessages.show(_toast, ToastMessages.survived())
		_warned["hp"] = false
	_prev_state = state


func _update_warn(key: String, ratio: float, data: Dictionary) -> void:
	if ratio >= RESET_RATIO:
		_warned[key] = false
		return
	if ratio >= CRITICAL_RATIO:
		return
	if _warned[key]:
		return
	_warned[key] = true
	ToastMessages.show(_toast, data)
