extends Node2D

var width = 16
var height = 16
var _scale = 1
var water_level = 0.0
var map = []

@onready var tile_map = $TileMap

enum TileType {
	WATER,
	CORNER_TOP_LEFT,
	CORNER_TOP_RIGHT,
	CORNER_BOTTOM_LEFT,
	CORNER_BOTTOM_RIGHT,
	EDGE_HORIZONTAL,
	EDGE_HORIZONTAL_FLIPPED,
	EDGE_VERTICAL,
	EDGE_VERTICAL_FLIPPED,
}

func detect_tile(x, y):
	var possible_values = range(0, 10)
	if map[y - 1].length == 0:
		if map[y].length == 0:
			return possible_values[randi_range(0, 10)]


func generate_map():
	map[0] = []
	for y in range(1, 20):
		if map[y] == null:
			map[y] = []
		
		for x in range(1, 20):
			if map[y][x] == null:
				var tile = detect_tile(x, y)

func int_to_field_type(value: int):
	match value:
		1: TileType.WATER
		2: TileType.CORNER_TOP_LEFT
		3: TileType.CORNER_TOP_RIGHT
		4: TileType.CORNER_BOTTOM_LEFT
		5: TileType.CORNER_BOTTOM_RIGHT
		6: TileType.EDGE_HORIZONTAL
		7: TileType.EDGE_HORIZONTAL_FLIPPED
		8: TileType.EDGE_VERTICAL
		9: TileType.EDGE_VERTICAL_FLIPPED

func tile_type_to_coords(tile_type: TileType):
	match tile_type:
		TileType.WATER:
			return Vector2i(10, 1)
		TileType.CORNER_TOP_LEFT:
			return Vector2i(8, 4)
		TileType.CORNER_TOP_RIGHT:
			return Vector2i(9, 4)
		TileType.CORNER_BOTTOM_LEFT:
			return Vector2i(8, 0)
		TileType.CORNER_BOTTOM_RIGHT:
			return Vector2i(9, 0)
		TileType.EDGE_HORIZONTAL:
			return Vector2i(10, 0)
		TileType.EDGE_HORIZONTAL_FLIPPED:
			return Vector2i(10, 4)
		TileType.EDGE_VERTICAL:
			return Vector2i(9, 1)
		TileType.EDGE_VERTICAL_FLIPPED:
			return Vector2i(8, 1)
