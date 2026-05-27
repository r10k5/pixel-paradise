class_name Biome
extends RefCounted

enum BiomeType {
	GRASSLAND,
	FOREST,
	DESERT,
	SNOW,
	SWAMP,
	RIVER,
	LAKE,
}

var biome_type: BiomeType
var display_name: String
var min_height: float = -1.0
var max_height: float = 1.0
var min_moisture: float = 0.0
var max_moisture: float = 1.0
var temperature_range: Vector2 = Vector2(0.5, 0.8)
var grass_tiles: Array[Vector2i] = []
var decoration_chance: float = 0.1
var allowed_decorations: Array[String] = []

func _init(type: BiomeType, biome_name: String) -> void:
	biome_type = type
	display_name = biome_name

func matches(height: float, moisture: float, temperature: float) -> bool:
	return (
		height >= min_height and height <= max_height
		and moisture >= min_moisture and moisture <= max_moisture
		and temperature >= temperature_range.x and temperature <= temperature_range.y
	)

static func create_default_biomes() -> Array[Biome]:
	# Сначала узкие биомы, луг — последний (fallback).
	var biomes: Array[Biome] = []

	var forest := Biome.new(BiomeType.FOREST, "Forest")
	forest.min_height = -0.22
	forest.max_height = 0.5
	forest.min_moisture = 0.58
	forest.max_moisture = 1.0
	forest.temperature_range = Vector2(0.25, 0.85)
	forest.decoration_chance = 0.58
	# Деревья и кусты чаще грибов (вес через повторы в массиве).
	forest.allowed_decorations = [
		"tree", "tree", "tree", "tree", "tree", "tree",
		"bush", "bush",
		"mushroom",
	]
	biomes.append(forest)

	var desert := Biome.new(BiomeType.DESERT, "Desert")
	desert.min_height = -0.1
	desert.max_height = 0.6
	desert.min_moisture = 0.0
	desert.max_moisture = 0.28
	desert.temperature_range = Vector2(0.68, 1.0)
	desert.decoration_chance = 0.03
	desert.allowed_decorations = ["cactus", "rock"]
	biomes.append(desert)

	var snow := Biome.new(BiomeType.SNOW, "Snow")
	snow.min_height = 0.38
	snow.max_height = 1.0
	snow.min_moisture = 0.0
	snow.max_moisture = 1.0
	snow.temperature_range = Vector2(0.0, 0.32)
	snow.decoration_chance = 0.05
	snow.allowed_decorations = ["pine_tree", "ice_rock"]
	biomes.append(snow)

	var swamp := Biome.new(BiomeType.SWAMP, "Swamp")
	swamp.min_height = -0.5
	swamp.max_height = -0.15
	swamp.min_moisture = 0.72
	swamp.max_moisture = 1.0
	swamp.temperature_range = Vector2(0.15, 0.95)
	swamp.decoration_chance = 0.15
	swamp.allowed_decorations = ["reed", "lilypad"]
	biomes.append(swamp)

	var grassland := Biome.new(BiomeType.GRASSLAND, "Grassland")
	grassland.min_height = -0.22
	grassland.max_height = 0.35
	grassland.min_moisture = 0.0
	grassland.max_moisture = 1.0
	grassland.temperature_range = Vector2(0.0, 1.0)
	grassland.decoration_chance = 0.08
	biomes.append(grassland)

	return biomes
