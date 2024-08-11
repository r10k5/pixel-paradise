extends Node2D

# Время суток
var time_of_day : float = 0.0  # 0.0 - утро, 1.0 - ночь
var day_duration : float = 60.0  # Длительность одного дня в секундах

# Ссылки на узлы
@onready var canvas_modulate : CanvasModulate = $CanvasModulate

func _ready():
	# Устанавливаем начальное состояние освещения
	update_lighting()

func _process(delta):
	# Обновляем время суток
	time_of_day += delta / day_duration
	if time_of_day >= 1.0:
		time_of_day -= 1.0  # Начинаем новый цикл

	# Обновляем освещение
	update_lighting()

func update_lighting():
	# Определяем цвета для разных фаз суток
	var morning_color = Color(1, 0.8, 0.6, 1)
	var day_color = Color(1, 1, 1, 1)
	var evening_color = Color(0.8, 0.6, 1, 1)
	var night_color = Color(0.4, 0.4, 0.6, 1)

	var color : Color

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

	# Устанавливаем цвет освещения сцены
	canvas_modulate.color = color
