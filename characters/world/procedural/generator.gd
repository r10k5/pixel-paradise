var width = 50
var height = 50
var scale = 0.1
var type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH

func generate_height_map():
	var noise = FastNoiseLite.new()
	var height_map = []
	
	noise.seed = randi()
	
	for y in range(height):
		var row = []
		for x in range(width):
			var height_value = noise.get_noise_2d(x * scale, y * scale)
			row.append(height_value)
		height_map.append(row)
	return height_map
