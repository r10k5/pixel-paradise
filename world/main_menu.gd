extends Control

const WORLD_SCENE := preload("res://world/main.tscn")

@onready var seed_input: LineEdit = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/SeedInput
@onready var start_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/StartButton
@onready var hint_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HintLabel

func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	seed_input.text_submitted.connect(func(_v: String): _on_start_pressed())

func _on_start_pressed() -> void:
	var world := WORLD_SCENE.instantiate()
	var parsed_seed := _parse_seed(seed_input.text)
	var world_generator := world.get_node_or_null("WorldGenerator")
	if world_generator != null:
		world_generator.map_seed = parsed_seed
		world_generator.auto_generate_on_ready = false
		world_generator.pre_generate_before_start = true
		world_generator.limit_world_size = true

	var multiverse := world.get_node_or_null("MultiverseManager")
	if multiverse != null:
		multiverse.base_seed = parsed_seed

	var tree := get_tree()
	var old_scene := tree.current_scene
	tree.root.add_child(world)
	tree.current_scene = world
	if old_scene != null:
		old_scene.queue_free()

func _parse_seed(text: String) -> int:
	var t := text.strip_edges()
	if t.is_empty():
		return 0
	if not t.is_valid_int():
		return 0
	return int(t)
