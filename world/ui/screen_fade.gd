extends ColorRect

signal fade_out_finished
signal fade_in_finished

@export var fade_duration: float = 0.45

var _tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	color = Color.BLACK
	modulate.a = 0.0
	visible = true


func fade_out() -> void:
	_kill_tween()
	modulate.a = 0.0
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 1.0, fade_duration)
	_tween.finished.connect(func() -> void: fade_out_finished.emit(), CONNECT_ONE_SHOT)


func fade_in() -> void:
	_kill_tween()
	modulate.a = 1.0
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	_tween.finished.connect(func() -> void: fade_in_finished.emit(), CONNECT_ONE_SHOT)


func await_fade_out() -> void:
	if modulate.a >= 0.99:
		return
	fade_out()
	await fade_out_finished


func await_fade_in() -> void:
	if modulate.a <= 0.01:
		modulate.a = 0.0
		return
	fade_in()
	await fade_in_finished


func _kill_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
