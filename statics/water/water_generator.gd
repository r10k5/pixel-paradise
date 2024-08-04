extends Node2D

var water_level = -0.25
var map = []
var generator = preload("res://characters/world/procedural/generator.gd")

@onready var tile_map = $TileMap
@onready var timer = $Timer
var already_generated = false

enum TileType {
	Center,
	Top,
	Bottom,
	Left,
	Right,
	LeftTopCorner,
	RightTopCorner,
	LeftBottomCorner,
	RightBottomCorner,
	VerticalTopCorner,
	VerticalBottomCorner,
	VerticalCenter,
	HorizontalLeftCorner,
	HorizontalRightCorner,
	HorizontalCenter,
	Puddle,
}

func get_tile(height_map: Array, x: int, y: int):
	var current_height = height_map[y][x]
	
	if current_height >= water_level:
		return null
	
	var height = len(height_map)
	var width = len(height_map[y])
	var left = x > 0 and height_map[y][x - 1] < water_level
	var right = x < width - 1 and height_map[y][x + 1] < water_level
	var top = y > 0 and height_map[y - 1][x] < water_level
	var bottom = y < height - 1 and height_map[y + 1][x] < water_level
	
	if left and right and top and bottom:
		return TileType.Center
		
	if not left and not right and not top and not bottom:
		return TileType.Puddle
		
	if bottom and not left and not right and not top:
		return TileType.VerticalTopCorner
		
	if bottom and top and not left and not right:
		return TileType.VerticalCenter
		
	if top and not left and not right and not bottom:
		return TileType.VerticalBottomCorner
		
	if left and not right and not top and not bottom:
		return TileType.HorizontalRightCorner
		
	if right and not left and not top and not bottom:
		return TileType.HorizontalLeftCorner
		
	if left and right and not top and not bottom:
		return TileType.HorizontalCenter
		
	if left and right and bottom:
		return TileType.Top
	
	if left and right and top:
		return TileType.Bottom
		
	if right and top and bottom:
		return TileType.Left
		
	if left and top and bottom:
		return TileType.Right
		
	if left and top:
		return TileType.RightBottomCorner
	
	if right and top:
		return TileType.LeftBottomCorner
		
	if left and bottom:
		return TileType.RightTopCorner
		
	if right and bottom:
		return TileType.LeftTopCorner
		
	if left and right or top and bottom:
		return TileType.Center
		
	return TileType.Center

func _input(event):
	if event.is_action("generate"):
		generate()

func _ready():
	generate()

func generate():
	if already_generated:
		return
	
	already_generated = true
	timer.start()
	timer.timeout.connect(
		func():
			already_generated = false
			timer.stop()
	)
	tile_map.clear()
	var procedural_generator = generator.new()
	procedural_generator.scale = 1.5
	var height_map: Array = procedural_generator.generate_height_map()
	
	for y in range(len(height_map)):
		for x in range(len(height_map[y])):
			var tile_type = get_tile(height_map, x, y)
			
			if tile_type != null:
				tile_map.set_cell(0, Vector2i(x, y), 0, tile_type_to_vector(tile_type))

func tile_type_to_vector(tile_type: TileType):
	match tile_type:
		TileType.Center:
			return Vector2i(10, 1)
		TileType.Left:
			return Vector2i(6, 6)
		TileType.Top:
			return Vector2i(7, 8)
		TileType.Right:
			return Vector2i(10, 6)
		TileType.Bottom:
			return Vector2i(7, 12)
		TileType.LeftTopCorner:
			return Vector2i(6, 5)
		TileType.RightTopCorner:
			return Vector2i(10, 5)
		TileType.LeftBottomCorner:
			return Vector2i(6, 7)
		TileType.RightBottomCorner:
			return Vector2i(10, 7)
		TileType.VerticalTopCorner:
			return Vector2i(5, 8)
		TileType.VerticalBottomCorner:
			return Vector2i(5, 10)
		TileType.VerticalCenter:
			return Vector2i(5, 9)
		TileType.HorizontalLeftCorner:
			return Vector2i(3, 11)
		TileType.HorizontalRightCorner:
			return Vector2i(5, 11)
		TileType.HorizontalCenter:
			return Vector2i(4, 11)
		TileType.Puddle:
			return Vector2i(4, 13)
		
