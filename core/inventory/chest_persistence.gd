class_name ChestPersistence
extends RefCounted

const SAVE_VERSION := 1


static func save_path(chest_uid: String) -> String:
	return "user://saves/chests/%s.json" % chest_uid


static func save(chest: Chest) -> bool:
	if chest == null or chest.chest_uid.is_empty():
		return false
	DirAccess.make_dir_recursive_absolute("user://saves/chests")
	var data := {
		"version": SAVE_VERSION,
		"loot_generated": chest.loot_generated,
		"slots": chest.storage.to_save_data(),
	}
	var file := FileAccess.open(save_path(chest.chest_uid), FileAccess.WRITE)
	if file == null:
		push_warning("ChestPersistence: cannot write %s" % chest.chest_uid)
		return false
	file.store_string(JSON.stringify(data, "\t"))
	return true


static func load(chest: Chest) -> bool:
	if chest == null or chest.chest_uid.is_empty():
		return false
	var path := save_path(chest.chest_uid)
	if not FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return false
	chest.set_loot_generated(bool(parsed.get("loot_generated", false)))
	var slots: Variant = parsed.get("slots", [])
	if slots is Array:
		chest.storage.load_from_save_data(slots)
		return true
	return false
