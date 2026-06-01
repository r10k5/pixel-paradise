class_name SurvivalPersistence
extends RefCounted

const SAVE_VERSION := 1


static func save_path(player_id: String) -> String:
	return "user://saves/%s/survival.json" % player_id


static func save(stats: SurvivalStats, player_id: String) -> bool:
	if stats == null or player_id.is_empty():
		return false
	DirAccess.make_dir_recursive_absolute("user://saves/%s" % player_id)
	var data := {
		"version": SAVE_VERSION,
		"hp": stats.hp,
		"hunger": stats.hunger,
		"stamina": stats.stamina,
	}
	var file := FileAccess.open(save_path(player_id), FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data, "\t"))
	return true


static func load(stats: SurvivalStats, player_id: String) -> bool:
	if stats == null or player_id.is_empty():
		return false
	var path := save_path(player_id)
	if not FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return false
	stats.hp = float(parsed.get("hp", stats.max_hp))
	stats.hunger = float(parsed.get("hunger", stats.max_hunger))
	stats.stamina = float(parsed.get("stamina", stats.max_stamina))
	stats.sync_display()
	return true
