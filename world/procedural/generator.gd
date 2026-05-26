class_name HeightMapGenerator
extends RefCounted

var width: int = 80
var height: int = 45
var scale: float = 0.08
var seed: int = 0

func generate_height_map() -> Array:
	var noise := FastNoiseLite.new()
	noise.seed = seed if seed != 0 else randi()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = scale
	noise.fractal_octaves = 4
	noise.fractal_lacunarity = 2.0
	noise.fractal_gain = 0.5

	var height_map: Array = []
	for y in range(height):
		var row: Array = []
		for x in range(width):
			row.append(noise.get_noise_2d(x, y))
		height_map.append(row)
	return height_map
