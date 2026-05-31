class_name ItemFactory
extends RefCounted

## Загружаем базовый скрипт предметов до сцен, чтобы `extends PickupItem` всегда резолвился.
const _PICKUP_ITEM_SCRIPT := preload("res://statics/pick-up-items/items/pickup_item.gd")

const SCENE_PATHS: Dictionary = {
	"item:forest_berry": "res://statics/pick-up-items/items/forest_berry_item.tscn",
	"item:shadow_grass": "res://statics/pick-up-items/items/shadow_grass_item.tscn",
	"item:oak_root": "res://statics/pick-up-items/items/oak_root_item.tscn",
	"item:elf_tear": "res://statics/pick-up-items/items/elf_tear_item.tscn",
	"item:mushroom": "res://statics/pick-up-items/items/mushroom_item.tscn",
	"item:log": "res://statics/drop/log.tscn",
	"item:bomb": "res://statics/bomb/bomb_item.tscn",
	"item:axe": "res://statics/tools/axe_base.tscn",
	"item:pickaxe": "res://statics/tools/pickaxe_base.tscn",
}

static var _scene_cache: Dictionary = {}


static func create(item_id: String) -> BaseEntity:
	var path: String = SCENE_PATHS.get(item_id, "")
	if path.is_empty():
		push_warning("ItemFactory: unknown item_id %s" % item_id)
		return null
	if not _scene_cache.has(item_id):
		var packed: PackedScene = load(path) as PackedScene
		if packed == null:
			push_error("ItemFactory: failed to load scene %s" % path)
			return null
		_scene_cache[item_id] = packed
	var scene: PackedScene = _scene_cache[item_id]
	var entity := scene.instantiate() as BaseEntity
	PickupIcons.apply_to_item(entity, item_id)
	return entity


static func has_item(item_id: String) -> bool:
	return SCENE_PATHS.has(item_id)


static func registered_ids() -> Array:
	return SCENE_PATHS.keys()
