extends Node2D

# Время суток и дата
# time_of_day: 0.0 = 00:00, 1.0 = 24:00 (цикл)
var time_of_day : float = 0.0
var day_duration : float = 120.0  # Длительность одного дня в секундах
var current_day : int = 1
var current_month : int = 1
var total_days_in_month : int = 30  # Можно сделать массив для разного количества дней в месяцах

# Слегка затемняем кадр в лесу (поверх цикла день/ночь).
const FOREST_DARKEN_BLEND := 0.38
const FOREST_TINT := Color(0.063, 0.125, 0.059, 0.624)
const FOREST_FADE_SPEED := 2.5

var _forest_darkness_target: float = 0.0
var _forest_darkness: float = 0.0

# Ссылки на узлы
@onready var canvas_modulate : CanvasModulate = $CanvasModulate
@onready var time_label : Label = $"../UI/TimeLabel"
@onready var date_label : Label = $"../UI/DateLabel"

func set_forest_darkness(amount: float) -> void:
	_forest_darkness_target = clampf(amount, 0.0, 1.0)

func _ready():
	# Устанавливаем начальное состояние освещения
	update_lighting()
	# Обновляем дату и время
	update_time_display()

func _process(delta):
	# Обновляем время суток
	time_of_day += delta / day_duration
	# Защита от NaN/битых значений: NaN ломает lerp и может привести к "невидимому" CanvasModulate.
	if time_of_day != time_of_day:
		time_of_day = 0.0
	time_of_day = clampf(time_of_day, 0.0, 1.0)
	if time_of_day >= 1.0:
		time_of_day -= 1.0  # Начинаем новый цикл
		increment_day()  # Переход на следующий день

	_forest_darkness = move_toward(
		_forest_darkness, _forest_darkness_target, FOREST_FADE_SPEED * delta
	)

	# Обновляем освещение
	update_lighting()

	# Обновляем отображение времени
	update_time_display()

func increment_day():
	current_day += 1
	if current_day > total_days_in_month:
		current_day = 1
		current_month += 1
		if current_month > 12:
			current_month = 1  # Начинаем новый год

func update_time_display():
	# Внутриигровое время в часах
	var hours = int(time_of_day * 24)
	var minutes = int((time_of_day * 24 - hours) * 60)

	# Обновляем текстовые метки
	time_label.text = "Time: %02d:%02d" % [hours, minutes]
	date_label.text = "Date: %02d/%02d" % [current_day, current_month]

func update_lighting():
	if canvas_modulate == null:
		return
	# Определяем цвета для разных фаз суток (только RGB; alpha всегда 1).
	var morning_color := Color(0.85, 0.88, 0.95, 1.0)
	var day_color := Color(1.0, 1.0, 1.0, 1.0)
	var evening_color := Color(1.0, 0.829, 0.608, 1.0)
	var night_color := Color(0.299, 0.34, 0.614, 1.0)

	var color: Color

	# Переходы по реальным окнам:
	# ночь: 22:00–06:00
	# утро: 06:00–09:00
	# день: 09:00–18:00
	# вечер: 18:00–22:00
	var hour := time_of_day * 24.0
	if hour < 6.0:
		# 00:00–06:00: ночь -> утро
		color = night_color.lerp(morning_color, hour / 6.0)
	elif hour < 9.0:
		# 06:00–09:00: утро -> день
		color = morning_color.lerp(day_color, (hour - 6.0) / 3.0)
	elif hour < 18.0:
		# 09:00–18:00: день -> вечер
		color = day_color.lerp(evening_color, (hour - 9.0) / 9.0)
	elif hour < 22.0:
		# 18:00–22:00: вечер -> ночь
		color = evening_color.lerp(night_color, (hour - 18.0) / 4.0)
	else:
		# 22:00–24:00: вечер -> ночь (короткий отрезок)
		color = evening_color.lerp(night_color, (hour - 22.0) / 2.0)

	if color != color:
		color = Color.WHITE
	if _forest_darkness > 0.001:
		color = color.lerp(FOREST_TINT, _forest_darkness * FOREST_DARKEN_BLEND)
	color.a = 1.0
	canvas_modulate.color = color
