class_name WorldMap
extends RefCounted

enum Terrain {
	GRASS,
	WATER,
	PATH,
}

var spawn_tile: Vector2i = Vector2i.ZERO

var _rng := RandomNumberGenerator.new()
var _height_noise: FastNoiseLite
var _plaza_noise: FastNoiseLite
var _vertical_noise: FastNoiseLite
var _horizontal_noise: FastNoiseLite
var _flower_noise: FastNoiseLite

func generate(_map_width: int, _map_height: int, map_seed: int = 0) -> void:
	_rng.seed = map_seed if map_seed != 0 else randi()
	_setup_noises(_rng.seed)
	spawn_tile = _find_spawn_tile_near(Vector2i.ZERO)

func get_path_style(tile: Vector2i) -> int:
	var v := absf(_vertical_noise.get_noise_2d(tile.x, tile.y))
	var h := absf(_horizontal_noise.get_noise_2d(tile.x, tile.y))
	if v < 0.028:
		return PathAutotile.Style.VERTICAL
	if h < 0.028:
		return PathAutotile.Style.HORIZONTAL
	return PathAutotile.Style.PLAZA

func get_grass_atlas(tile: Vector2i) -> Vector2i:
	if is_water(tile):
		return _pick_grass_under_water(tile)
	return _pick_grass(tile)

func height_at(tile: Vector2i) -> float:
	return _height_noise.get_noise_2d(tile.x, tile.y)

func is_spawnable(tile: Vector2i) -> bool:
	return is_grass(tile)

func is_path(tile: Vector2i) -> bool:
	if is_water(tile):
		return false
	var n := absf(_plaza_noise.get_noise_2d(tile.x, tile.y))
	var v := absf(_vertical_noise.get_noise_2d(tile.x, tile.y))
	var h := absf(_horizontal_noise.get_noise_2d(tile.x, tile.y))
	return n < 0.065 or v < 0.028 or h < 0.028

func is_water(tile: Vector2i) -> bool:
	return height_at(tile) < -0.22

func is_grass(tile: Vector2i) -> bool:
	return not is_water(tile) and not is_path(tile)

func tile_to_world(tile: Vector2i, tile_size: int, map_scale: float) -> Vector2:
	return Vector2(tile) * float(tile_size) * map_scale + Vector2(tile_size, tile_size) * 0.5 * map_scale

func world_to_tile(world_pos: Vector2, tile_size: int, map_scale: float) -> Vector2i:
	var local := world_pos / (float(tile_size) * map_scale)
	return Vector2i(floori(local.x), floori(local.y))

func _setup_noises(seed_value: int) -> void:
	_height_noise = FastNoiseLite.new()
	_height_noise.seed = seed_value + 1
	_height_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_height_noise.frequency = 0.035
	_height_noise.fractal_octaves = 4
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

func _pick_grass_under_water(tile: Vector2i) -> Vector2i:
	return GrassTiles.GRASS_UNDER_WATER[abs(int(tile.x * 13 + tile.y * 11)) % GrassTiles.GRASS_UNDER_WATER.size()]
