extends Node

const PROFILE_PATH := "user://profile.cfg"
const SECTION := "player"
const KEY_ID := "player_id"

var player_id: String = ""


func _ready() -> void:
	_load_or_create()


func _load_or_create() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(PROFILE_PATH)
	if err == OK:
		player_id = str(cfg.get_value(SECTION, KEY_ID, ""))
	if player_id.is_empty():
		player_id = _generate_id()
		cfg.set_value(SECTION, KEY_ID, player_id)
		cfg.save(PROFILE_PATH)


func _generate_id() -> String:
	return "%d-%08d" % [Time.get_unix_time_from_system(), randi() % 100000000]
