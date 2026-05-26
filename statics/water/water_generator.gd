extends Node2D

# Вода рисуется через WorldGenerator. Клавиша 2 — перегенерация мира.

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("generate"):
		var world_gen: Node = get_parent().get_node_or_null("WorldGenerator")
		if world_gen and world_gen.has_method("regenerate"):
			world_gen.regenerate()
