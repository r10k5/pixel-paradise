class_name DecorationGenerator
extends RefCounted

const DECORATION_TYPES := {
	"tree": {"scenes": ["res://statics/tree/tree.tscn"], "chance": 0.02, "entity_id": "passive-entity:tree"},
	"bush": {"scenes": ["res://statics/tree/kust.tscn"], "chance": 0.04, "entity_id": "passive-entity:kust"},
	"mushroom": {"scenes": ["res://statics/mushrooms/mushroom.tscn"], "chance": 0.015, "entity_id": "passive-entity:mushroom"},
	"rock": {"scenes": ["res://statics/stone/stone.tscn"], "chance": 0.03, "entity_id": "passive-entity:stone"},
	"cactus": {"scenes": [], "chance": 0.02, "entity_id": ""},
	"pine_tree": {"scenes": [], "chance": 0.025, "entity_id": ""},
	"ice_rock": {"scenes": ["res://statics/stone/stone.tscn"], "chance": 0.02, "entity_id": "passive-entity:stone"},
	"reed": {"scenes": [], "chance": 0.04, "entity_id": ""},
	"lilypad": {"scenes": [], "chance": 0.03, "entity_id": ""},
}

var _world_seed: int = 0
var _decoration_multiplier: float = 1.0

func _init(seed_value: int, decoration_multiplier: float = 1.0) -> void:
	_world_seed = seed_value
	_decoration_multiplier = decoration_multiplier

func should_place_decoration(
	tile: Vector2i,
	biome: Biome,
	world_map: WorldMap,
	used_tiles: Dictionary
) -> Dictionary:
	if used_tiles.has(tile):
		return {}
	if not world_map.is_grass(tile):
		return {}
	if _is_near_water(tile, world_map):
		return {}

	var global_tile := world_map.to_global_tile(tile)
	var roll := randf_from_seed(global_tile, _world_seed)
	var chance := biome.decoration_chance * _decoration_multiplier
	if roll > chance:
		return {}

	if biome.allowed_decorations.is_empty():
		return {}

	var decor_index := absi(
		global_tile.x * 73856093 ^ global_tile.y * 19349663 ^ _world_seed
	) % biome.allowed_decorations.size()
	var decor_type: String = biome.allowed_decorations[decor_index]

	if not DECORATION_TYPES.has(decor_type):
		return {}

	var decor_data: Dictionary = DECORATION_TYPES[decor_type]
	var type_chance := _type_chance(biome, decor_type, float(decor_data.chance))
	var decor_chance := randf_from_seed(global_tile, _world_seed + 1000)
	if decor_chance > type_chance:
		return {}

	var scenes: Array = decor_data.scenes
	if scenes.is_empty():
		return {}

	return {
		"type": decor_type,
		"entity_id": decor_data.entity_id,
		"scene": scenes[0],
	}

static func spacing_for_biome(biome: Biome, default_spacing: int) -> int:
	if biome != null and biome.biome_type == Biome.BiomeType.FOREST:
		return maxi(1, default_spacing - 1)
	return default_spacing

## Минимальный отступ за границу чанка: радиус mark_blocked (не шире spacing).
static func chunk_neighbor_margin(default_spacing: int) -> int:
	return maxi(1, default_spacing)

static func _type_chance(biome: Biome, decor_type: String, default_chance: float) -> float:
	if biome == null:
		return default_chance
	match biome.biome_type:
		Biome.BiomeType.FOREST:
			match decor_type:
				"tree":
					return 0.28
				"bush":
					return 0.12
				"mushroom":
					return 0.04
				_:
					return default_chance
		Biome.BiomeType.SWAMP:
			match decor_type:
				"mushroom":
					return 0.32
				"bush":
					return 0.10
				"tree":
					return 0.05
				_:
					return default_chance
		Biome.BiomeType.GRASSLAND:
			match decor_type:
				"rock":
					return 0.35
				"bush":
					return 0.07
				"mushroom":
					return 0.05
				_:
					return default_chance
		_:
			return default_chance

static func mark_blocked(used_tiles: Dictionary, tile: Vector2i, spacing: int) -> void:
	for dy in range(-spacing, spacing + 1):
		for dx in range(-spacing, spacing + 1):
			used_tiles[Vector2i(tile.x + dx, tile.y + dy)] = true

static func _is_near_water(tile: Vector2i, world_map: WorldMap) -> bool:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if world_map.is_water(tile + Vector2i(dx, dy)):
				return true
	return false

static func randf_from_seed(tile: Vector2i, seed_offset: int) -> float:
	var hash := absi(tile.x * 2654435761 ^ tile.y * 2246822519 ^ seed_offset)
	return float(hash % 10000) / 10000.0
