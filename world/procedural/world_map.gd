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

const CACHE_MAX_SIZE := 65535

var spawn_tile: Vector2i = Vector2i.ZERO
var biomes: Array[Biome] = []
var settings: WorldGenerationSettings
var _river_biome: Biome
var _lake_biome: Biome

var _biome_map: Dictionary = {}
var _height_cache: Dictionary = {}
var _moisture_cache: Dictionary = {}
var _temperature_cache: Dictionary = {}
var _river_channel_cache: Dictionary = {}
var _lake_channel_cache: Dictionary = {}
var _advanced_params_cache: Dictionary = {}

var _rng := RandomNumberGenerator.new()
var _height_noise: FastNoiseLite
var _plaza_noise: FastNoiseLite
var _vertical_noise: FastNoiseLite
var _horizontal_noise: FastNoiseLite
var _flower_noise: FastNoiseLite
var _moisture_noise: FastNoiseLite
var _temperature_noise: FastNoiseLite
var _river_noise: FastNoiseLite
var _lake_noise: FastNoiseLite
var _puddle_noise: FastNoiseLite
var _advanced_generator: AdvancedWorldGenerator

func generate(_map_width: int, _map_height: int, map_seed: int = 0, gen_settings: WorldGenerationSettings = null) -> void:
	settings = gen_settings if gen_settings != null else WorldGenerationSettings.new()
	_rng.seed = map_seed if map_seed != 0 else randi()
	if settings.use_advanced_generator:
		_advanced_generator = AdvancedWorldGenerator.new(int(_rng.seed), settings.height_frequency)
	else:
		_advanced_generator = null
	_setup_noises(_rng.seed)
	_clear_caches()

	if settings.enable_biomes:
		biomes = Biome.create_default_biomes()
	else:
		biomes = []
	_init_water_biomes()

	spawn_tile = _find_spawn_tile_near(Vector2i.ZERO)

	if settings.enable_biomes and settings.biome_precompute_radius > 0:
		_precompute_biome_map(settings.biome_precompute_radius)

func get_biome(tile: Vector2i) -> Biome:
	if not settings.enable_biomes or biomes.is_empty():
		return biomes[0] if not biomes.is_empty() else null

	if _biome_map.has(tile):
		return _biome_map[tile]

	if is_river(tile):
		_cache_biome(tile, _river_biome)
		return _river_biome

	if is_lake(tile):
		_cache_biome(tile, _lake_biome)
		return _lake_biome

	var height := height_at(tile)
	var moisture := moisture_at(tile)
	var temperature := temperature_at(tile)
	if settings.use_advanced_generator:
		var advanced_biome := _select_biome_advanced(tile, height, moisture, temperature)
		if advanced_biome != null:
			_cache_biome(tile, advanced_biome)
			return advanced_biome

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
	var result := _sample_height(tile)
	if _height_cache.size() >= CACHE_MAX_SIZE:
		_height_cache.clear()
	_height_cache[tile] = result
	return result

func moisture_at(tile: Vector2i) -> float:
	if _moisture_cache.has(tile):
		return _moisture_cache[tile]
	var result := _sample_moisture(tile)
	if _moisture_cache.size() >= CACHE_MAX_SIZE:
		_moisture_cache.clear()
	_moisture_cache[tile] = result
	return result

func temperature_at(tile: Vector2i) -> float:
	if _temperature_cache.has(tile):
		return _temperature_cache[tile]
	var result := _sample_temperature(tile)
	if _temperature_cache.size() >= CACHE_MAX_SIZE:
		_temperature_cache.clear()
	_temperature_cache[tile] = result
	return result

func continentalness_at(tile: Vector2i) -> float:
	if _advanced_generator != null:
		return clampf(_get_advanced_params(tile).get("continentalness", 0.0), -1.0, 1.0)
	# Fallback: высота даёт грубую "континентальность".
	return clampf(height_at(tile) * 0.9, -1.0, 1.0)

func erosion_at(tile: Vector2i) -> float:
	if _advanced_generator != null:
		return clampf(_get_advanced_params(tile).get("erosion", 0.0), -1.0, 1.0)
	# Fallback: используем дорожный шум как прокси неоднородности рельефа.
	return clampf(_plaza_noise.get_noise_2d(tile.x, tile.y), -1.0, 1.0)

func is_spawnable(tile: Vector2i) -> bool:
	return is_grass(tile)

func is_path(tile: Vector2i) -> bool:
	if is_lake(tile) or is_river(tile) or _is_puddle_candidate(tile):
		return false
	return _path_noise_at(tile)

func _path_noise_at(tile: Vector2i) -> bool:
	var n := absf(_plaza_noise.get_noise_2d(tile.x, tile.y))
	var v := absf(_vertical_noise.get_noise_2d(tile.x, tile.y))
	var h := absf(_horizontal_noise.get_noise_2d(tile.x, tile.y))
	return n < settings.path_density or v < settings.path_thickness or h < settings.path_thickness

func is_water(tile: Vector2i) -> bool:
	return is_lake(tile)

func is_river(tile: Vector2i) -> bool:
	return false

func is_lake(tile: Vector2i) -> bool:
	if not _is_base_water(tile):
		return false
	return _is_lake_cluster(tile)

func is_puddle(tile: Vector2i) -> bool:
	return false

func _is_puddle_candidate(tile: Vector2i) -> bool:
	if _is_base_water(tile):
		return false
	if height_at(tile) < settings.puddle_level:
		return true
	var n := _puddle_noise.get_noise_2d(tile.x, tile.y)
	if n < settings.puddle_threshold:
		return false
	var roll := _tile_roll01(tile, 991)
	return roll < settings.puddle_spawn_chance

func is_grass(tile: Vector2i) -> bool:
	return not is_water(tile) and not is_path(tile)

func tile_to_world(tile: Vector2i, tile_size: int, map_scale: float) -> Vector2:
	return Vector2(tile) * float(tile_size) * map_scale + Vector2(tile_size, tile_size) * 0.5 * map_scale

func world_to_tile(world_pos: Vector2, tile_size: int, map_scale: float) -> Vector2i:
	var local := world_pos / (float(tile_size) * map_scale)
	return Vector2i(floori(local.x), floori(local.y))

func _precompute_biome_map(radius: int) -> void:
	_precompute_lake_clusters_in_rect(-radius, radius, -radius, radius)
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
	_river_channel_cache.clear()
	_lake_channel_cache.clear()
	_advanced_params_cache.clear()

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

	_river_noise = FastNoiseLite.new()
	_river_noise.seed = seed_value + 557
	_river_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_river_noise.frequency = settings.river_frequency
	_river_noise.fractal_octaves = 1

	_lake_noise = FastNoiseLite.new()
	_lake_noise.seed = seed_value + 593
	_lake_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_lake_noise.frequency = settings.lake_frequency
	_lake_noise.fractal_octaves = 2
	_lake_noise.fractal_gain = 0.55

	_puddle_noise = FastNoiseLite.new()
	_puddle_noise.seed = seed_value + 661
	_puddle_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_puddle_noise.frequency = settings.puddle_frequency

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
		Biome.BiomeType.DESERT:
			return GrassTiles.BIOME_SAND
		Biome.BiomeType.SNOW:
			return GrassTiles.pick_snow_tile(tile)
		Biome.BiomeType.SWAMP:
			return GrassTiles.GRASS_PLAIN[abs(int(tile.x * 31 + tile.y * 19)) % GrassTiles.GRASS_PLAIN.size()]
		_:
			return _pick_grass(tile)

func _pick_grass_under_water(tile: Vector2i) -> Vector2i:
	return GrassTiles.GRASS_UNDER_WATER[abs(int(tile.x * 13 + tile.y * 11)) % GrassTiles.GRASS_UNDER_WATER.size()]

func _tile_roll01(tile: Vector2i, salt: int) -> float:
	var hash := absi(tile.x * 73856093 ^ tile.y * 19349663 ^ int(_rng.seed) ^ salt)
	return float(hash % 10000) / 10000.0

func _is_river_channel(tile: Vector2i) -> bool:
	var key := "%d,%d" % [tile.x, tile.y]
	if _river_channel_cache.has(key):
		return _river_channel_cache[key]

	var result := false
	var half_width := maxi(settings.river_min_half_width, 1)
	var min_len := maxi(settings.river_min_length_tiles, 1)
	var max_gap := 2

	for offset in range(-half_width, half_width + 1):
		var vertical_tile := tile + Vector2i(offset, 0)
		var vertical_len := _river_line_core_length(vertical_tile, Vector2i(0, 1), min_len, max_gap)
		if vertical_len >= min_len:
			result = true
			break

		var horizontal_tile := tile + Vector2i(0, offset)
		var horizontal_len := _river_line_core_length(horizontal_tile, Vector2i(1, 0), min_len, max_gap)
		if horizontal_len >= min_len:
			result = true
			break

	if _river_channel_cache.size() >= CACHE_MAX_SIZE:
		_river_channel_cache.clear()
	_river_channel_cache[key] = result
	return result

func _is_lake_cluster(tile: Vector2i) -> bool:
	var key := _tile_key(tile)
	if _lake_channel_cache.has(key):
		return _lake_channel_cache[key]
	if not _is_lake_core(tile):
		_cache_lake_cluster_result(key, false)
		return false
	return _label_lake_component(tile)

func _is_lake_basin(tile: Vector2i) -> bool:
	var h := height_at(tile)
	if h > settings.water_level + settings.lake_height_bias:
		return false
	var n := _lake_noise.get_noise_2d(tile.x, tile.y)
	return n > settings.lake_threshold

func _is_base_water(tile: Vector2i) -> bool:
	return height_at(tile) < settings.water_level

func _init_water_biomes() -> void:
	_river_biome = Biome.new(Biome.BiomeType.RIVER, "River")
	_river_biome.decoration_chance = 0.0
	_lake_biome = Biome.new(Biome.BiomeType.LAKE, "Lake")
	_lake_biome.decoration_chance = 0.0

func _is_river_core(tile: Vector2i) -> bool:
	if not _is_base_water(tile):
		return false
	var n := absf(_river_noise.get_noise_2d(tile.x, tile.y))
	return n < settings.river_width

func _river_line_core_length(tile: Vector2i, dir: Vector2i, target_len: int, max_gap: int) -> int:
	if not _is_river_core(tile):
		return 0
	var core_count := 1
	core_count += _river_line_core_length_one_side(tile, dir, target_len, max_gap)
	if core_count >= target_len:
		return core_count
	core_count += _river_line_core_length_one_side(tile, -dir, target_len, max_gap)
	return core_count

func _river_line_core_length_one_side(start_tile: Vector2i, dir: Vector2i, target_len: int, max_gap: int) -> int:
	var core_count := 0
	var gap_streak := 0
	for step in range(1, target_len * 2):
		var tile := start_tile + dir * step
		if _is_river_core(tile):
			core_count += 1
			gap_streak = 0
			if core_count >= target_len:
				return core_count
		else:
			gap_streak += 1
			if gap_streak > max_gap:
				break
	return core_count

func _is_lake_core(tile: Vector2i) -> bool:
	if not _is_base_water(tile):
		return false
	return _is_lake_basin(tile)

func _precompute_lake_clusters_in_rect(x_min: int, x_max: int, y_min: int, y_max: int) -> void:
	for y in range(y_min, y_max):
		for x in range(x_min, x_max):
			var tile := Vector2i(x, y)
			if _lake_channel_cache.has(_tile_key(tile)):
				continue
			if _is_lake_core(tile):
				_label_lake_component(tile)

func _label_lake_component(start: Vector2i) -> bool:
	var start_key := _tile_key(start)
	if _lake_channel_cache.has(start_key):
		return _lake_channel_cache[start_key]

	var required := maxi(settings.lake_min_size_tiles, 1)
	var component: Array[Vector2i] = []
	var queue: Array[Vector2i] = [start]
	var visited: Dictionary = {start_key: true}
	var dirs: Array[Vector2i] = [
		Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)
	]

	while not queue.is_empty():
		var tile: Vector2i = queue.pop_back()
		component.append(tile)
		for d in dirs:
			var next: Vector2i = tile + d
			var key := _tile_key(next)
			if visited.has(key):
				continue
			if not _is_lake_core(next):
				continue
			visited[key] = true
			queue.append(next)

	var is_lake := component.size() >= required
	for labeled in component:
		_cache_lake_cluster_result(_tile_key(labeled), is_lake)
	return is_lake

func _cache_lake_cluster_result(key: String, is_lake: bool) -> void:
	if _lake_channel_cache.size() >= CACHE_MAX_SIZE:
		_lake_channel_cache.clear()
	_lake_channel_cache[key] = is_lake

func _tile_key(tile: Vector2i) -> String:
	return "%d,%d" % [tile.x, tile.y]

func _get_advanced_params(tile: Vector2i) -> Dictionary:
	if _advanced_generator == null:
		return {}
	var key := _tile_key(tile)
	if _advanced_params_cache.has(key):
		return _advanced_params_cache[key]
	var sample := _advanced_generator.sample(tile)
	if _advanced_params_cache.size() >= CACHE_MAX_SIZE:
		_advanced_params_cache.clear()
	_advanced_params_cache[key] = sample
	return sample

func _sample_height(tile: Vector2i) -> float:
	if _advanced_generator == null:
		return _height_noise.get_noise_2d(tile.x, tile.y)
	return _get_advanced_params(tile).get("height", 0.0)

func _sample_moisture(tile: Vector2i) -> float:
	if _advanced_generator == null:
		var n := _moisture_noise.get_noise_2d(tile.x, tile.y)
		return (n + 1.0) * 0.5
	return _get_advanced_params(tile).get("wetness", 0.5)

func _sample_temperature(tile: Vector2i) -> float:
	if _advanced_generator == null:
		var n := _temperature_noise.get_noise_2d(tile.x, tile.y)
		return (n + 1.0) * 0.5
	return _get_advanced_params(tile).get("temperature", 0.5)

func _select_biome_advanced(tile: Vector2i, _height: float, moisture: float, temperature: float) -> Biome:
	var cont := continentalness_at(tile)
	var er := erosion_at(tile)

	# Базовая многомерная классификация (этап 2): континентальность + эрозия + климат.
	if temperature < 0.35:
		return _find_land_biome(Biome.BiomeType.SNOW)
	if temperature > 0.62 and moisture < 0.45:
		return _find_land_biome(Biome.BiomeType.DESERT)
	if moisture > 0.72 and cont < 0.15 and er < -0.1:
		return _find_land_biome(Biome.BiomeType.SWAMP)
	if moisture > 0.58 and temperature < 0.82 and er <= 0.45:
		return _find_land_biome(Biome.BiomeType.FOREST)
	return _find_land_biome(Biome.BiomeType.GRASSLAND)

func _find_land_biome(target_type: Biome.BiomeType) -> Biome:
	for biome in biomes:
		if biome.biome_type == target_type:
			return biome
	return biomes[0] if not biomes.is_empty() else null
