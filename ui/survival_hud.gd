extends CanvasLayer

@onready var hp_bar: ProgressBar = $MarginContainer/VBoxContainer/HPBar
@onready var hunger_bar: ProgressBar = $MarginContainer/VBoxContainer/HungerBar
@onready var stamina_bar: ProgressBar = $MarginContainer/VBoxContainer/StaminaBar
@onready var hungry_icon: TextureRect = $MarginContainer/VBoxContainer/Icons/HungryIcon
@onready var exhausted_icon: TextureRect = $MarginContainer/VBoxContainer/Icons/ExhaustedIcon
@onready var vignette: ColorRect = $Vignette

var _stats: SurvivalStats

const COLOR_OK := Color(0.35, 0.85, 0.4)
const COLOR_WARN := Color(0.95, 0.85, 0.25)
const COLOR_CRIT := Color(0.92, 0.28, 0.22)


func bind(stats: SurvivalStats) -> void:
	if _stats != null:
		_disconnect(_stats)
	_stats = stats
	if _stats == null:
		return
	_stats.hp_changed.connect(_on_hp_changed)
	_stats.hunger_changed.connect(_on_hunger_changed)
	_stats.stamina_changed.connect(_on_stamina_changed)
	_stats.state_changed.connect(_on_state_changed)
	_on_hp_changed(_stats.hp)
	_on_hunger_changed(_stats.hunger)
	_on_stamina_changed(_stats.stamina)
	_on_state_changed(_stats.current_state)


func _disconnect(stats: SurvivalStats) -> void:
	if stats.hp_changed.is_connected(_on_hp_changed):
		stats.hp_changed.disconnect(_on_hp_changed)
	if stats.hunger_changed.is_connected(_on_hunger_changed):
		stats.hunger_changed.disconnect(_on_hunger_changed)
	if stats.stamina_changed.is_connected(_on_stamina_changed):
		stats.stamina_changed.disconnect(_on_stamina_changed)
	if stats.state_changed.is_connected(_on_state_changed):
		stats.state_changed.disconnect(_on_state_changed)


func _on_hp_changed(value: float) -> void:
	_style_bar(hp_bar, value, _stats.max_hp)


func _on_hunger_changed(value: float) -> void:
	_style_bar(hunger_bar, value, _stats.max_hunger)


func _on_stamina_changed(value: float) -> void:
	_style_bar(stamina_bar, value, _stats.max_stamina)
	_update_vignette()


func _on_state_changed(state: SurvivalStats.SurvivalState) -> void:
	if hungry_icon:
		hungry_icon.visible = state == SurvivalStats.SurvivalState.HUNGRY
	if exhausted_icon:
		exhausted_icon.visible = state == SurvivalStats.SurvivalState.EXHAUSTED
	_update_vignette()


func _style_bar(bar: ProgressBar, value: float, max_value: float) -> void:
	if bar == null:
		return
	bar.max_value = max_value
	bar.value = value
	var ratio := value / maxf(1.0, max_value)
	var fill := bar.get_theme_stylebox("fill") as StyleBoxFlat
	if fill == null:
		fill = StyleBoxFlat.new()
	if ratio < 0.2:
		fill.bg_color = COLOR_CRIT
	elif ratio < 0.5:
		fill.bg_color = COLOR_WARN
	else:
		fill.bg_color = COLOR_OK
	bar.add_theme_stylebox_override("fill", fill)
	_update_vignette()


func _update_vignette() -> void:
	if vignette == null or _stats == null:
		return
	var critical := (
		_stats.hp / _stats.max_hp < 0.2
		or _stats.hunger / _stats.max_hunger < 0.2
		or _stats.stamina / _stats.max_stamina < 0.2
	)
	vignette.visible = critical
	if critical:
		vignette.color = Color(0.45, 0.05, 0.05, 0.22)
	else:
		vignette.color = Color(0, 0, 0, 0)