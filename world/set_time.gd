extends Node2D

# Время суток и дата
var time_of_day : float = 0.0  # 0.0 - утро, 1.0 - ночь
var day_duration : float = 120.0  # Длительность одного дня в секундах
var current_day : int = 1
var current_month : int = 1
var total_days_in_month : int = 30  # Можно сделать массив для разного количества дней в месяцах

# Ссылки на узлы
@onready var canvas_modulate : CanvasModulate = $CanvasModulate
@onready var time_label : Label = $"../UI/TimeLabel"
@onready var date_label : Label = $"../UI/DateLabel"

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
	var evening_color := Color(1.0, 0.92, 0.82, 1.0)
	var night_color := Color(0.55, 0.6, 0.85, 1.0)

	var color: Color

	# Утро (0.0 - 0.25)
	if time_of_day < 0.25:
		color = morning_color.lerp(day_color, time_of_day / 0.25)

	# День (0.25 - 0.5)
	elif time_of_day < 0.5:
		color = day_color.lerp(evening_color, (time_of_day - 0.25) / 0.25)

	# Вечер (0.5 - 0.75)
	elif time_of_day < 0.75:
		color = evening_color.lerp(night_color, (time_of_day - 0.5) / 0.25)

	# Ночь (0.75 - 1.0)
	else:
		color = night_color.lerp(morning_color, (time_of_day - 0.75) / 0.25)

	if color != color:
		color = Color.WHITE
	color.a = 1.0
	canvas_modulate.color = color
