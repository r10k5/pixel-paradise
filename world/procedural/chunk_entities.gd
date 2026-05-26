class_name ChunkEntities
extends RefCounted

const TREE_ID := "passive-entity:tree"
const KUST_ID := "passive-entity:kust"
const MUSHROOM_ID := "passive-entity:mushroom"

# Вероятность на клетку травы (детерминированно по сиду + координатам).
const TREE_TILE_CHANCE := 45
const KUST_TILE_CHANCE := 28
const MUSHROOM_TILE_CHANCE := 12

# Минимальная дистанция между любыми объектами (деревья/кусты/грибы) в клетках.
# Это нужно, чтобы спрайты/хиты не накладывались друг на друга.
const MIN_ENTITY_SPACING_TILES := 2

# Буфер от воды по клеткам.
# Иногда визуально дерево "залезает" на воду из-за размера спрайта/коллайдера,
# поэтому запрещаем спавн также рядом с водной линией.
const MIN_DISTANCE_FROM_WATER_TILES := 1

static func _is_spawn_surface(world_map: WorldMap, tile: Vector2i) -> bool:
	# Жестко запрещаем спавн на воде, даже если где-то логика "grass" расходится.
	if world_map.is_water(tile):
		return false
	if world_map.is_path(tile):
		return false

	# Запрещаем спавн рядом с водой (радиусом).
	var r := MIN_DISTANCE_FROM_WATER_TILES
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			var t := Vector2i(tile.x + dx, tile.y + dy)
			if world_map.is_water(t):
				return false

	return world_map.is_grass(tile)

static func _mark_blocked(used_tiles: Dictionary, tile: Vector2i) -> void:
	# Блокируем окрестность вокруг выбранной клетки.
	# Используем "круг" по евклидову расстоянию (квадрат расстояния), чтобы
	# запрет был симметричным.
	var r := MIN_ENTITY_SPACING_TILES
	var r2 := r * r
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			if dx * dx + dy * dy <= r2:
				used_tiles[Vector2i(tile.x + dx, tile.y + dy)] = true

static func get_placements(
	world_seed: int,
	chunk: Vector2i,
	chunk_size: int,
	world_map: WorldMap
) -> Dictionary:
	var placements: Dictionary = {
		TREE_ID: [],
		KUST_ID: [],
		MUSHROOM_ID: [],
	}

	var start_x := chunk.x * chunk_size
	var start_y := chunk.y * chunk_size
	var used_tiles: Dictionary = {}

	for y in range(start_y, start_y + chunk_size):
		for x in range(start_x, start_x + chunk_size):
			var tile := Vector2i(x, y)
			if used_tiles.has(tile):
				continue
			if not _is_spawn_surface(world_map, tile):
				continue

			var tree_roll: int = _tile_roll(world_seed, tile, 101)
			if tree_roll < TREE_TILE_CHANCE:
				placements[TREE_ID].append(tile)
				_mark_blocked(used_tiles, tile)
				continue

			var kust_roll: int = _tile_roll(world_seed, tile, 202)
			if kust_roll < KUST_TILE_CHANCE:
				placements[KUST_ID].append(tile)
				_mark_blocked(used_tiles, tile)
				continue

			var mushroom_roll: int = _tile_roll(world_seed, tile, 303)
			if mushroom_roll < MUSHROOM_TILE_CHANCE and not used_tiles.has(tile):
				placements[MUSHROOM_ID].append(tile)
				_mark_blocked(used_tiles, tile)

	return placements

static func tile_key(tile: Vector2i) -> String:
	return "%d,%d" % [tile.x, tile.y]

## Стабильный ключ словаря для координат чанка (надёжнее, чем Vector2i как ключ Variant).
static func world_chunk_key(chunk: Vector2i) -> String:
	return "%d,%d" % [chunk.x, chunk.y]

static func world_chunk_from_key(key: String) -> Vector2i:
	var parts: PackedStringArray = key.split(",")
	if parts.size() != 2:
		push_error("chunk_entities.gd: bad chunk key %s" % key)
		return Vector2i.ZERO
	return Vector2i(int(parts[0]), int(parts[1]))

static func _tile_roll(world_seed: int, tile: Vector2i, salt: int) -> int:
	return absi(tile.x * 73856093 ^ tile.y * 19349663 ^ world_seed ^ salt) % 1000
