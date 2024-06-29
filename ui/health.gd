extends CanvasLayer

@onready var progress_bar = $Control/ProgressBar

func set_hp(hp: int):
	progress_bar.value = hp
	
func set_max_hp(max_hp: int):
	progress_bar.max_value = max_hp
