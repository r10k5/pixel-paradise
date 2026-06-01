class_name BiomeLayerConfig
extends RefCounted

## Слои биомов: один TileSet (TX Tileset Grass.png) на каждый TileMapLayer, цвет через Modulate.

const LAYER_GRASSLAND := "GrasslandLayer"
const LAYER_FOREST := "ForestLayer"
const LAYER_DESERT := "DesertLayer"
const LAYER_SNOW := "SnowLayer"
const LAYER_SWAMP := "SwampLayer"

const ALL_LAYER_NAMES: Array[String] = [
	LAYER_GRASSLAND,
	LAYER_FOREST,
	LAYER_DESERT,
	LAYER_SNOW,
	LAYER_SWAMP,
]

const MODULATE_GRASSLAND := Color(1, 1, 1, 1)
const MODULATE_FOREST := Color("#8fbc8f")
const MODULATE_DESERT := Color("e7bf6ae1")
const MODULATE_SNOW := Color("997cfee6")
const MODULATE_SWAMP := Color("#6b8e6b")


static func reference_layer(terrain_root: Node2D) -> TileMapLayer:
	return terrain_root.get_node_or_null(LAYER_GRASSLAND) as TileMapLayer


static func tile_pixel_size(terrain_root: Node2D) -> Vector2:
	var layer := reference_layer(terrain_root)
	if layer == null or layer.tile_set == null:
		return Vector2(16, 16) * terrain_root.scale
	return Vector2(layer.tile_set.tile_size) * terrain_root.scale


static func modulate_for(biome_type: Biome.BiomeType) -> Color:
	match biome_type:
		Biome.BiomeType.FOREST:
			return MODULATE_FOREST
		Biome.BiomeType.DESERT:
			return MODULATE_DESERT
		Biome.BiomeType.SNOW:
			return MODULATE_SNOW
		Biome.BiomeType.SWAMP:
			return MODULATE_SWAMP
		_:
			return MODULATE_GRASSLAND


static func layer_name_for(biome_type: Biome.BiomeType) -> String:
	match biome_type:
		Biome.BiomeType.FOREST:
			return LAYER_FOREST
		Biome.BiomeType.DESERT:
			return LAYER_DESERT
		Biome.BiomeType.SNOW:
			return LAYER_SNOW
		Biome.BiomeType.SWAMP:
			return LAYER_SWAMP
		_:
			return LAYER_GRASSLAND


static func get_layer(terrain_root: Node2D, biome_type: Biome.BiomeType) -> TileMapLayer:
	var layer_name := layer_name_for(biome_type)
	var layer := terrain_root.get_node_or_null(layer_name) as TileMapLayer
	if layer != null:
		return layer
	return terrain_root.get_node_or_null(LAYER_GRASSLAND) as TileMapLayer


static func apply_template_layers(dst_root: Node2D, template_root: Node2D) -> void:
	dst_root.scale = template_root.scale
	for layer_name in ALL_LAYER_NAMES:
		var dst := dst_root.get_node_or_null(layer_name) as TileMapLayer
		var src := template_root.get_node_or_null(layer_name) as TileMapLayer
		if dst == null or src == null:
			continue
		dst.tile_set = src.tile_set
		dst.modulate = src.modulate
		dst.z_index = src.z_index
		dst.rendering_quadrant_size = src.rendering_quadrant_size


static func biome_type_for_tile(world_map: WorldMap, tile: Vector2i) -> Biome.BiomeType:
	if world_map == null or not world_map.settings.enable_biomes:
		return Biome.BiomeType.GRASSLAND
	var biome := world_map.get_biome(tile)
	if biome == null:
		return Biome.BiomeType.GRASSLAND
	return biome.biome_type


static func get_layer_for_tile(
	terrain_root: Node2D, world_map: WorldMap, tile: Vector2i
) -> TileMapLayer:
	return get_layer(terrain_root, biome_type_for_tile(world_map, tile))
