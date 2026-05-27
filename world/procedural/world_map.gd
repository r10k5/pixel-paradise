class_name WorldMap
extends RefCounted

enum Terrain {
	GRASS,
	WATER,
	PATH,
	SAND,
	SNOW,
	SWAMP_GRASS,
}

const CACHE_MAX_SIZE := 4096

var spawn_tile: Vector2i = Vector2i.ZERO
var biomes: Array[Biome] = []
var settings: WorldGenerationSettings

var _biome_map: Dictionary = {}
var _height_cache: Dictionary = {}
var _moisture_cache: Dictionary = {}
var _temperature_cache: Dictionary = {}

var _rng := RandomNumberGenerator.new()
var _height_noise: FastNoiseLite
var _plaza_noise: FastNoiseLite
var _vertical_noise: FastNoiseLite
var _horizontal_noise: FastNoiseLite
var _flower_noise: FastNoiseLite
var _moisture_noise: FastNoiseLite
var _temperature_noise: FastNoiseLite

func generate(_map_width: int, _map_height: int, map_seed: int = 0, gen_settings: WorldGenerationSettings = null) -> void:
	settings = gen_settings if gen_settings != null else WorldGenerationSettings.new()
	_rng.seed = map_seed if map_seed != 0 else randi()
	_setup_noises(_rng.seed)
	_clear_caches()

	if settings.enable_biomes:
		biomes = Biome.create_default_biomes()
	else:
		biomes = []

	spawn_tile = _find_spawn_tile_near(Vector2i.ZERO)

	if settings.enable_biomes and settings.biome_precompute_radius > 0:
		_precompute_biome_map(settings.biome_precompute_radius)

func get_biome(tile: Vector2i) -> Biome:
	if not settings.enable_biomes or biomes.is_empty():
		return biomes[0] if not biomes.is_empty() else null

	if _biome_map.has(tile):
		return _biome_map[tile]

	var height := height_at(tile)
	var moisture := moisture_at(tile)
	var temperature := temperature_at(tile)

	for biome in biomes:
		if biome.matches(height, moisture, temperature):
			_cache_biome(tile, biome)
			return biome

	_cache_biome(tile, biomes[0])
	return biomes[0]

func get_path_style(tile: Vector2i) -> int:
	var v := absf(_vertical_noise.get_noise_2d(tile.x, tile.y))
	var h := absf(_horizontal_noise.get_noise_2d(tile.x, tile.y))
	if v < settings.path_thickness:
		return PathAutotile.Style.VERTICAL
	if h < settings.path_thickness:
		return PathAutotile.Style.HORIZONTAL
	return PathAutotile.Style.PLAZA

func get_grass_atlas(tile: Vector2i) -> Vector2i:
	if is_water(tile):
		return _pick_grass_under_water(tile)
	if settings.enable_biomes and not biomes.is_empty():
		return _pick_grass_for_biome(tile, get_biome(tile))
	return _pick_grass(tile)

func height_at(tile: Vector2i) -> float:
	if _height_cache.has(tile):
		return _height_cache[tile]
	var result := _height_noise.get_noise_2d(tile.x, tile.y)
	if _height_cache.size() >= CACHE_MAX_SIZE:
		_height_cache.clear()
	_height_cache[tile] = result
	return result

func moisture_at(tile: Vector2i) -> float:
	if _moisture_cache.has(tile):
		return _moisture_cache[tile]
	var n := _moisture_noise.get_noise_2d(tile.x, tile.y)
	var result := (n + 1.0) * 0.5
	if _moisture_cache.size() >= CACHE_MAX_SIZE:
		_moisture_cache.clear()
	_moisture_cache[tile] = result
	return result

func temperature_at(tile: Vector2i) -> float:
	if _temperature_cache.has(tile):
		return _temperature_cache[tile]
	var n := _temperature_noise.get_noise_2d(tile.x, tile.y)
	var result := (n + 1.0) * 0.5
	if _temperature_cache.size() >= CACHE_MAX_SIZE:
		_temperature_cache.clear()
	_temperature_cache[tile] = result
	return result

func is_spawnable(tile: Vector2i) -> bool:
	return is_grass(tile)

func is_path(tile: Vector2i) -> bool:
	if is_water(tile):
		return false
	var n := absf(_plaza_noise.get_noise_2d(tile.x, tile.y))
	var v := absf(_vertical_noise.get_noise_2d(tile.x, tile.y))
	var h := absf(_horizontal_noise.get_noise_2d(tile.x, tile.y))
	return n < settings.path_density or v < settings.path_thickness or h < settings.path_thickness

func is_water(tile: Vector2i) -> bool:
	return height_at(tile) < settings.water_level

func is_grass(tile: Vector2i) -> bool:
	return not is_water(tile) and not is_path(tile)

func tile_to_world(tile: Vector2i, tile_size: int, map_scale: float) -> Vector2:
	return Vector2(tile) * float(tile_size) * map_scale + Vector2(tile_size, tile_size) * 0.5 * map_scale

func world_to_tile(world_pos: Vector2, tile_size: int, map_scale: float) -> Vector2i:
	var local := world_pos / (float(tile_size) * map_scale)
	return Vector2i(floori(local.x), floori(local.y))

func _precompute_biome_map(radius: int) -> void:
	for y in range(-radius, radius):
		for x in range(-radius, radius):
			get_biome(Vector2i(x, y))

func _cache_biome(tile: Vector2i, biome: Biome) -> void:
	if _biome_map.size() >= CACHE_MAX_SIZE:
		_biome_map.clear()
	_biome_map[tile] = biome

func _clear_caches() -> void:
	_biome_map.clear()
	_height_cache.clear()
	_moisture_cache.clear()
	_temperature_cache.clear()

func _setup_noises(seed_value: int) -> void:
	_height_noise = FastNoiseLite.new()
	_height_noise.seed = seed_value + 1
	_height_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_height_noise.frequency = settings.height_frequency
	_height_noise.fractal_octaves = settings.height_octaves
	_height_noise.fractal_lacunarity = 2.0
	_height_noise.fractal_gain = 0.5

	_plaza_noise = FastNoiseLite.new()
	_plaza_noise.seed = seed_value + 29
	_plaza_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_plaza_noise.frequency = 0.018

	_vertical_noise = FastNoiseLite.new()
	_vertical_noise.seed = seed_value + 97
	_vertical_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_vertical_noise.frequency = 0.055

	_horizontal_noise = FastNoiseLite.new()
	_horizontal_noise.seed = seed_value + 131
	_horizontal_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_horizontal_noise.frequency = 0.055

	_flower_noise = FastNoiseLite.new()
	_flower_noise.seed = seed_value + 211
	_flower_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_flower_noise.frequency = 0.12

	_moisture_noise = FastNoiseLite.new()
	_moisture_noise.seed = seed_value + 337
	_moisture_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_moisture_noise.frequency = settings.moisture_frequency
	_moisture_noise.fractal_octaves = 2
	_moisture_noise.fractal_gain = 0.55

	_temperature_noise = FastNoiseLite.new()
	_temperature_noise.seed = seed_value + 443
	_temperature_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_temperature_noise.frequency = settings.temperature_frequency
	_temperature_noise.fractal_octaves = 2
	_temperature_noise.fractal_gain = 0.5

func _find_spawn_tile_near(center: Vector2i) -> Vector2i:
	if is_spawnable(center):
		return center
	for r in range(1, 128):
		for y in range(center.y - r, center.y + r + 1):
			for x in range(center.x - r, center.x + r + 1):
				var tile := Vector2i(x, y)
				if is_spawnable(tile):
					return tile
	return center

func _pick_grass(tile: Vector2i) -> Vector2i:
	var n := _flower_noise.get_noise_2d(tile.x, tile.y)
	if n > 0.62:
		return GrassTiles.GRASS_FLOWERS[abs(int(tile.x * 17 + tile.y * 23)) % GrassTiles.GRASS_FLOWERS.size()]
	return GrassTiles.GRASS_PLAIN[abs(int(tile.x * 31 + tile.y * 19)) % GrassTiles.GRASS_PLAIN.size()]

func _pick_grass_for_biome(tile: Vector2i, biome: Biome) -> Vector2i:
	if biome == null:
		return _pick_grass(tile)
	match biome.biome_type:
		Biome.BiomeType.GRASSLAND:
			return _pick_grass(tile)
		Biome.BiomeType.FOREST:
			return GrassTiles.pick_forest_grass(tile)
		Biome.BiomeType.DESERT, Biome.BiomeType.SNOW, Biome.BiomeType.SWAMP:
			return GrassTiles.GRASS_PLAIN[abs(int(tile.x * 31 + tile.y * 19)) % GrassTiles.GRASS_PLAIN.size()]
		_:
			return _pick_grass(tile)

func _pick_grass_under_water(tile: Vector2i) -> Vector2i:
	return GrassTiles.GRASS_UNDER_WATER[abs(int(tile.x * 13 + tile.y * 11)) % GrassTiles.GRASS_UNDER_WATER.size()]
