class_name InventoryPersistence
extends RefCounted

const SAVE_VERSION := 1


static func save_path(player_id: String) -> String:
	return "user://saves/%s/inventory.json" % player_id


static func save(inventory: InventoryComponent, player_id: String) -> bool:
	if inventory == null or player_id.is_empty():
		return false
	var dir_path := "user://saves/%s" % player_id
	DirAccess.make_dir_recursive_absolute(dir_path)
	var data := {
		"version": SAVE_VERSION,
		"slots": inventory.to_save_data(),
	}
	var file := FileAccess.open(save_path(player_id), FileAccess.WRITE)
	if file == null:
		push_warning("InventoryPersistence: cannot write %s" % save_path(player_id))
		return false
	file.store_string(JSON.stringify(data, "\t"))
	return true


static func load(inventory: InventoryComponent, player_id: String) -> bool:
	if inventory == null or player_id.is_empty():
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
	var slots: Variant = parsed.get("slots", [])
	if slots is Array:
		inventory.load_from_save_data(slots)
		return true
	return false
