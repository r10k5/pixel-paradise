class_name LootGenerator
extends RefCounted

const TABLE_PATHS: Dictionary = {
	"forest_easy": "res://core/loot/loot_tables/forest_easy.tres",
	"forest_normal": "res://core/loot/loot_tables/forest_normal.tres",
	"grassland_normal": "res://core/loot/loot_tables/grassland_normal.tres",
}

static var _cache: Dictionary = {}


static func fill_chest(
	storage: InventoryComponent,
	loot_table_id: String,
	seed_value: int,
	biome_type: Biome.BiomeType,
	difficulty: String
) -> void:
	if storage == null:
		return
	var table_key := _resolve_table_key(loot_table_id, biome_type, difficulty)
	var table := _load_table(table_key)
	if table == null:
		table = _default_table()
	var rng := RandomNumberGenerator.new()
	if seed_value != 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	var rolls := 2 + rng.randi_range(0, 2)
	for _i in rolls:
		var entry := _pick_entry(table, rng)
		if entry == null or entry.item_id.is_empty():
			continue
		var count := rng.randi_range(entry.min_count, maxi(entry.min_count, entry.max_count))
		storage.add_item_by_id(entry.item_id, count)


static func _resolve_table_key(loot_table_id: String, biome_type: Biome.BiomeType, difficulty: String) -> String:
	if not loot_table_id.is_empty() and TABLE_PATHS.has(loot_table_id):
		return loot_table_id
	match biome_type:
		Biome.BiomeType.FOREST:
			return "forest_%s" % difficulty if difficulty in ["easy", "normal", "hard"] else "forest_normal"
		_:
			return "grassland_%s" % difficulty if difficulty in ["easy", "normal", "hard"] else "grassland_normal"


static func _load_table(key: String) -> LootTable:
	if _cache.has(key):
		return _cache[key]
	var path: String = TABLE_PATHS.get(key, "")
	if path.is_empty():
		return null
	var res := load(path) as LootTable
	if res != null:
		_cache[key] = res
	return res


static func _default_table() -> LootTable:
	var table := LootTable.new()
	var berry := LootEntry.new()
	berry.item_id = "item:forest_berry"
	berry.weight = 3.0
	berry.min_count = 1
	berry.max_count = 3
	var mushroom := LootEntry.new()
	mushroom.item_id = "item:mushroom"
	mushroom.weight = 2.0
	mushroom.min_count = 1
	mushroom.max_count = 2
	table.entries = [berry, mushroom]
	return table


static func _pick_entry(table: LootTable, rng: RandomNumberGenerator) -> LootEntry:
	if table == null or table.entries.is_empty():
		return null
	var total := 0.0
	for entry in table.entries:
		if entry != null:
			total += maxf(0.0, entry.weight)
	if total <= 0.0:
		return table.entries[0]
	var roll := rng.randf() * total
	var acc := 0.0
	for entry in table.entries:
		if entry == null:
			continue
		acc += maxf(0.0, entry.weight)
		if roll <= acc:
			return entry
	return table.entries.back()
