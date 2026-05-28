class_name AdvancedWorldGenerator
extends RefCounted

## Продвинутый sampler мира (без fixed map size):
## возвращает параметры по любой tile-координате.

var seed: int = 0
var scale: float = 0.05
var continentalness_scale: float = 0.008
var erosion_scale: float = 0.012
var warp_scale: float = 0.03
var warp_strength: float = 0.15

var _height_noise: FastNoiseLite
var _continentalness_noise: FastNoiseLite
var _erosion_noise: FastNoiseLite
var _wetness_noise: FastNoiseLite
var _temperature_noise: FastNoiseLite
var _warp_x_noise: FastNoiseLite
var _warp_y_noise: FastNoiseLite
var _warp_offset_noise: FastNoiseLite
var _detail_noise: FastNoiseLite

func _init(seed_value: int, base_scale: float = 0.05) -> void:
	seed = seed_value if seed_value != 0 else randi()
	scale = base_scale
	_setup_noises()

func sample(tile: Vector2i) -> Dictionary:
	var warped := _apply_domain_warping(Vector2(tile.x, tile.y))
	return {
		"height": _generate_height(warped),
		"continentalness": _generate_continentalness(warped),
		"erosion": _generate_erosion(warped),
		"wetness": _generate_wetness(warped),
		"temperature": _generate_temperature(warped),
	}

func _setup_noises() -> void:
	_height_noise = _create_noise(seed + 1, scale, 4)
	_continentalness_noise = _create_noise(seed + 100, continentalness_scale, 3)
	_erosion_noise = _create_noise(seed + 200, erosion_scale, 2)
	_wetness_noise = _create_noise(seed + 300, 0.01, 3)
	_temperature_noise = _create_noise(seed + 400, 0.008, 2)
	_warp_x_noise = _create_noise(seed + 500, warp_scale, 2)
	_warp_y_noise = _create_noise(seed + 600, warp_scale, 2)
	_warp_offset_noise = _create_noise(seed + 700, warp_scale * 2.0, 1)
	_detail_noise = _create_noise(seed + 999, scale * 3.0, 2)

func _create_noise(seed_val: int, freq: float, octaves: int) -> FastNoiseLite:
	var noise := FastNoiseLite.new()
	noise.seed = seed_val
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = freq
	noise.fractal_octaves = octaves
	noise.fractal_lacunarity = 2.0
	noise.fractal_gain = 0.5
	return noise

func _apply_domain_warping(coords: Vector2) -> Vector2:
	var warp_x := _warp_x_noise.get_noise_2d(coords.x, coords.y)
	var warp_y := _warp_y_noise.get_noise_2d(coords.x, coords.y)
	var warp_offset := _warp_offset_noise.get_noise_2d(coords.x, coords.y)

	var warped_x := coords.x + warp_x * warp_strength * 100.0
	var warped_y := coords.y + warp_y * warp_strength * 100.0
	warped_x += warp_offset * 20.0

	return Vector2(warped_x, warped_y)

func _generate_height(coords: Vector2) -> float:
	var base_height := _height_noise.get_noise_2d(coords.x, coords.y)
	var detail := _detail_noise.get_noise_2d(coords.x, coords.y) * 0.3
	return clampf(base_height + detail, -1.0, 1.0)

func _generate_continentalness(coords: Vector2) -> float:
	var value := _continentalness_noise.get_noise_2d(coords.x, coords.y)
	value = pow(value, 3.0)
	return clampf(value, -1.0, 1.0)

func _generate_erosion(coords: Vector2) -> float:
	var value := _erosion_noise.get_noise_2d(coords.x, coords.y)
	return clampf(value, -1.0, 1.0)

func _generate_wetness(coords: Vector2) -> float:
	var value := _wetness_noise.get_noise_2d(coords.x, coords.y)
	return clampf((value + 1.0) * 0.5, 0.0, 1.0)

func _generate_temperature(coords: Vector2) -> float:
	var value := _temperature_noise.get_noise_2d(coords.x, coords.y)
	return clampf((value + 1.0) * 0.5, 0.0, 1.0)
