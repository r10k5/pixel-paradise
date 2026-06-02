class_name ToastMessages

const COLOR_PICKUP := Color(0.55, 0.95, 0.55)
const COLOR_ERROR := Color(0.92, 0.28, 0.22)
const COLOR_HUNGER := Color(1.0, 0.55, 0.1)
const COLOR_STAMINA := Color(0.95, 0.85, 0.25)
const COLOR_HP := Color(0.45, 0.05, 0.05)
const COLOR_DEATH := Color(0.968, 0.968, 0.968, 1.0)
const COLOR_DYING := Color(0.92, 0.28, 0.22)
const COLOR_DYING_TIMER := Color(1.0, 0.55, 0.1)
const COLOR_SURVIVED := Color(0.55, 0.95, 0.55)


static func pickup(title: String, count: int) -> Dictionary:
	return {
		"text": "📦 Подобрано: %s x%d" % [title, count],
		"duration": 2.0,
		"color": COLOR_PICKUP,
	}


static func inventory_full() -> Dictionary:
	return {
		"text": "⚠ Инвентарь полон!",
		"duration": 2.5,
		"color": COLOR_ERROR,
	}


static func hunger_critical() -> Dictionary:
	return {
		"text": "⚠ ГОЛОД! Срочно поешьте!",
		"duration": 3.0,
		"color": COLOR_HUNGER,
	}


static func stamina_low() -> Dictionary:
	return {
		"text": "💤 Выносливость на исходе",
		"duration": 2.0,
		"color": COLOR_STAMINA,
	}


static func hp_critical() -> Dictionary:
	return {
		"text": "☠ ОПАСНОСТЬ! Здоровье критическое",
		"duration": 3.0,
		"color": COLOR_HP,
	}


static func player_died() -> Dictionary:
	return {
		"text": "💀 Вы погибли...",
		"duration": 5.0,
		"color": COLOR_DEATH,
	}


static func dying_entered() -> Dictionary:
	return {
		"text": "☠ КРИТИЧЕСКОЕ СОСТОЯНИЕ!",
		"duration": 3.0,
		"color": COLOR_DYING,
	}


static func dying_timer_hint() -> Dictionary:
	return {
		"text": "⏱ 60 секунд до смерти...",
		"duration": 4.0,
		"color": COLOR_DYING_TIMER,
	}


static func survived() -> Dictionary:
	return {
		"text": "✅ Вы выжили!",
		"duration": 2.0,
		"color": COLOR_SURVIVED,
	}


static func show(toast: ToastManager, data: Dictionary) -> void:
	if toast == null:
		return
	toast.show_toast(data["text"], data["duration"], data["color"])
