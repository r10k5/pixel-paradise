extends PointLight2D

func _ready():
	# Настройка параметров света
	light_2d.color = Color(1, 1, 0, 1)  # Ярко-жёлтый цвет
	light_2d.energy = 5.0  # Увеличиваем яркость
	light_2d.range = 100.0  # Устанавливаем радиус свечения

func _process(delta):
	# Можно добавить динамическое изменение, если нужно
	pass

